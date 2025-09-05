#!/usr/bin/env bash
set -euo pipefail

# Academic paper skeleton (LaTeX) + Zotero hydration TODO
# Usage:
#   ./run_paper.sh --provider=openai --topic="Productivity impacts of remote work" [--context=ctx.txt] [--model=MODEL]

usage() {
  echo "run_paper.sh --provider=openai|anthropic|azure --topic='...' [--context=FILE] [--model=NAME]"; exit 1;
}

need() { command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need curl; need jq

PROVIDER="openai"; TOPIC=""; CTX_FILE=""; MODEL=""
for arg in "$@"; do
  case "$arg" in
    --provider=*) PROVIDER="${arg#*=}" ;;
    --topic=*) TOPIC="${arg#*=}" ;;
    --context=*) CTX_FILE="${arg#*=}" ;;
    --model=*) MODEL="${arg#*=}" ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $arg"; usage ;;
  esac
done

[[ -z "$TOPIC" ]] && { echo "--topic required"; usage; }
if [[ -z "$CTX_FILE" ]]; then
  CTX_FILE="context.txt"
  cat > "$CTX_FILE" <<'EOF'
[#1] Smith 2021 (Journal of Productivity) "...remote work effects vary by autonomy..."
[#2] Meta 2023 (Meta-analysis) "...heterogeneity by industry and collaboration intensity..."
EOF
fi

SYSTEM='Output LaTeX only. Compile-safe macros. Use \section, \subsection, \label. Use \cite{key} only if a real key is provided; otherwise write [to-collect: key-hint]. No commentary.'
USER=$(cat <<USR
Context (--- delimited, cite with [#id] in text, not \cite):
---
$(cat "$CTX_FILE")
---

Task: Create a paper skeleton for:
$TOPIC

Include:
- \section{Introduction} (1 paragraph; [#id] inline citations)
- \section{Related Work}
- \section{Method}
- \section{Results}
- \section{Discussion}
- \section{Limitations}
- \section{Conclusion}
Add one figure and one table stub with \label.
USR
)

call_openai() {
  local messages="$1"; local temperature="$2"; local model="${MODEL:-${OPENAI_MODEL:-gpt-4o-mini}}"
  [[ -z "${OPENAI_API_KEY:-}" ]] && { echo "OPENAI_API_KEY not set"; exit 1; }
  curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
    -d @<(jq -n --arg m "$model" --argjson msgs "$messages" --argjson t "$temperature" '{model:$m,temperature:(t|tonumber),messages:$msgs}')
}

call_azure() {
  local messages="$1"; local temperature="$2";
  [[ -z "${AZURE_OPENAI_KEY:-}" || -z "${AZURE_OPENAI_ENDPOINT:-}" || -z "${AZURE_OPENAI_DEPLOYMENT:-}" || -z "${AZURE_OPENAI_API_VERSION:-}" ]] && { echo "Missing Azure vars"; exit 1; }
  curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
    -H "api-key: $AZURE_OPENAI_KEY" -H "Content-Type: application/json" \
    -d @<(jq -n --argjson msgs "$messages" --argjson t "$temperature" '{temperature:(t|tonumber),messages:$msgs}')
}

call_anthropic() {
  local system="$1"; local user="$2"; local temperature="$3";
  [[ -z "${ANTHROPIC_API_KEY:-}" ]] && { echo "ANTHROPIC_API_KEY not set"; exit 1; }
  curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -d @<(jq -n --arg s "$system" --arg u "$user" '{model:"claude-3-5-sonnet-20240620",max_tokens:2000,temperature:0.1,system:$s,messages:[{role:"user",content:$u}]}')
}

# 1) Generate LaTeX
case "$PROVIDER" in
  openai)
    msgs=$(jq -n --arg s "$SYSTEM" --arg u "$USER" '[{"role":"system","content":$s},{"role":"user","content":$u}]')
    call_openai "$msgs" 0.1 | jq -r '.choices[0].message.content' > paper.tex ;;
  azure)
    msgs=$(jq -n --arg s "$SYSTEM" --arg u "$USER" '[{"role":"system","content":$s},{"role":"user","content":$u}]')
    call_azure "$msgs" 0.1 | jq -r '.choices[0].message.content' > paper.tex ;;
  anthropic)
    call_anthropic "$SYSTEM" "$USER" 0.1 | jq -r '.content[0].text' > paper.tex ;;
  *) echo "Unknown provider: $PROVIDER"; exit 1 ;;
esac
echo "Wrote paper.tex"

# 2) Zotero TODO
PROMPT=$(cat <<'EOT'
From the outline topics and inline [#id] mentions, list the key references to collect. Do not fabricate. For each item output: [to-collect] title | venue | year | DOI/URL if known | suggested BibTeX key.
Outline:
<<<
EOT
)
INPUT="${PROMPT}$(cat paper.tex)
>>>
"

case "$PROVIDER" in
  openai)
    msgs=$(jq -n --arg u "$INPUT" '[{"role":"user","content":$u}]')
    call_openai "$msgs" 0 | jq -r '.choices[0].message.content' > zotero_todo.md ;;
  azure)
    msgs=$(jq -n --arg u "$INPUT" '[{"role":"user","content":$u}]')
    call_azure "$msgs" 0 | jq -r '.choices[0].message.content' > zotero_todo.md ;;
  anthropic)
    call_anthropic "" "$INPUT" 0 | jq -r '.content[0].text' > zotero_todo.md ;;
esac
echo "Done: paper.tex zotero_todo.md"

