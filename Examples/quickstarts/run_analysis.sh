#!/usr/bin/env bash
set -euo pipefail

# Data Analysis Plan + Report JSON + Vega-Lite chart
# Usage:
#   ./run_analysis.sh --provider=openai [--model=gpt-4o-mini] [--dataset=dataset.md]

usage(){ echo "run_analysis.sh --provider=openai|anthropic|azure [--model=NAME] [--dataset=FILE]"; exit 1; }
need(){ command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need curl; need jq

PROVIDER=openai; MODEL=""; DATASET=""
for arg in "$@"; do
  case "$arg" in
    --provider=*) PROVIDER="${arg#*=}" ;;
    --model=*) MODEL="${arg#*=}" ;;
    --dataset=*) DATASET="${arg#*=}" ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $arg"; usage ;;
  esac
done

if [[ -z "$DATASET" ]]; then
  DATASET=dataset.md
  cat > "$DATASET" <<'EOF'
Dataset: Employee productivity logs (daily), fields: date, employee_id, role, autonomy_score, tasks_completed, meetings_hours.
Goal: Estimate impact of remote work on productivity while controlling for role and autonomy.
Constraints: No PII export; code must run offline.
EOF
fi

plan_prompt=$(cat <<EOT
Return a JSON analysis plan with fields: questions, features, methods, confounders, validation. Use only the dataset/goals below.
Dataset & Goals:
<<<
$(cat "$DATASET")
>>>
EOT
)

report_prompt=$(cat <<EOT
Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.
Dataset & Goals:
<<<
$(cat "$DATASET")
>>>
EOT
)

call_openai() {
  local prompt="$1"; local json=0; local temperature="${2:-0}"; local model="${MODEL:-${OPENAI_MODEL:-gpt-4o-mini}}"
  [[ -z "${OPENAI_API_KEY:-}" ]] && { echo "OPENAI_API_KEY not set"; exit 1; }
  local body=$(jq -n --arg m "$model" --arg u "$prompt" --argjson t "$temperature" '{model:$m,temperature:(t|tonumber),messages:[{role:"user",content:$u}]}' )
  if [[ "$json" == 1 ]]; then body=$(echo "$body" | jq '. + {response_format:{type:"json_object"}}'); fi
  curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' -d "$body"
}

call_openai_json() { MODEL="$MODEL" OPENAI_MODEL="${OPENAI_MODEL:-gpt-4o-mini}" OPENAI_API_KEY="$OPENAI_API_KEY" bash -c 'curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @<(jq -n --arg m "'"${MODEL:-${OPENAI_MODEL:-gpt-4o-mini}}"'" --arg u "$0" '{model:$m,temperature:0,messages:[{role:"user",content:$u}],response_format:{type:"json_object"}}')' -- "$1"; }

call_azure_json() { curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" -H "api-key: $AZURE_OPENAI_KEY" -H 'Content-Type: application/json' -d @<(jq -n --arg u "$1" '{temperature:0,messages:[{role:"user",content:$u}],response_format:{type:"json_object"}}'); }

call_anthropic_json() { curl -s https://api.anthropic.com/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H 'Content-Type: application/json' -d @<(jq -n --arg u "$1" '{model:"claude-3-5-sonnet-20240620",max_tokens:2000,temperature:0,system:"Respond with JSON only",messages:[{role:"user",content:$u}]}'); }

# 1) Plan (JSON)
case "$PROVIDER" in
  openai) call_openai_json "$plan_prompt" | jq . > analysis_plan.json ;;
  azure)  call_azure_json  "$plan_prompt" | jq . > analysis_plan.json ;;
  anthropic) call_anthropic_json "$plan_prompt" | jq . > analysis_plan.json ;;
  *) echo "Unknown provider: $PROVIDER"; exit 1 ;;
esac
echo "Wrote analysis_plan.json"

# 2) Report (JSON)
case "$PROVIDER" in
  openai) call_openai_json "$report_prompt" > analysis_report.json ;;
  azure)  call_azure_json  "$report_prompt" > analysis_report.json ;;
  anthropic) call_anthropic_json "$report_prompt" > analysis_report.json ;;
esac
echo "Wrote analysis_report.json"

# 3) Extract chart and viewer
mkdir -p charts
jq -r '.charts[0].vegaLiteSpec' analysis_report.json > charts/chart1.json
cat > charts/view.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
<div id="vis"></div>
<script>
fetch('chart1.json').then(r=>r.json()).then(spec=>vegaEmbed('#vis', spec));
</script>
HTML
echo "Done: analysis_plan.json analysis_report.json charts/chart1.json charts/view.html"

