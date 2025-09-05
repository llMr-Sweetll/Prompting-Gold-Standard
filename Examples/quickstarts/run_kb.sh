#!/usr/bin/env bash
set -euo pipefail

# Knowledge Base: Entity/Relation extraction + Source trust graph + Update plan
# Usage:
#   ./run_kb.sh --provider=openai [--sources=sources.txt]

usage(){ echo "run_kb.sh --provider=openai|anthropic|azure [--sources=FILE]"; exit 1; }
need(){ command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need curl; need jq

PROVIDER=openai; SOURCES=""
for arg in "$@"; do
  case "$arg" in
    --provider=*) PROVIDER="${arg#*=}" ;;
    --sources=*) SOURCES="${arg#*=}" ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $arg"; usage ;;
  esac
done

if [[ -z "$SOURCES" ]]; then
  SOURCES=sources.txt
  cat > "$SOURCES" <<'EOF'
[#A] 2021 Journal Article: "Remote work effects vary by role autonomy" (peer-reviewed)
[#B] 2023 Meta-analysis: "Industry heterogeneity in productivity outcomes" (peer-reviewed)
[#C] Blog 2020: "Remote work always boosts productivity" (non-peer-reviewed)
EOF
fi

extract_prompt=$(cat <<EOT
From the context, extract:
- Entities (type, canonical name, aliases)
- Relations (subject, predicate, object, evidence [doc-id:quote])
Return JSON with two arrays: entities, relations. Do not add external facts.
Context:
<<<
$(cat "$SOURCES")
>>>
EOT
)

graph_prompt=$(cat <<EOT
Build a source graph:
- Nodes: sources with metadata (id, type, venue, year)
- Edges: citation/derivation links
Assign a trust score per node (0–1) with rationale: peer-reviewed recent > blog.
Return JSON {nodes:[], edges:[]} using only provided sources.
Sources:
<<<
$(cat "$SOURCES")
>>>
EOT
)

plan_prompt=$(cat <<'EOT'
Given new docs below, propose updates to the KB:
- New entities/relations with evidence
- Retractions/contradictions
- Sections to rewrite
Return a concise Markdown plan with priorities.
New Docs:
[#D] 2024 RCT: "Collaboration overhead increases remote latency" (peer-reviewed)
EOT
)

openai_json(){ curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' -d @<(jq -n --arg m "${OPENAI_MODEL:-gpt-4o-mini}" --arg u "$1" '{model:$m,temperature:0,messages:[{role:"user",content:$u}],response_format:{type:"json_object"}}'); }
azure_json(){ curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" -H "api-key: $AZURE_OPENAI_KEY" -H 'Content-Type: application/json' -d @<(jq -n --arg u "$1" '{temperature:0,messages:[{role:"user",content:$u}],response_format:{type:"json_object"}}'); }
anthropic_json(){ curl -s https://api.anthropic.com/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H 'Content-Type: application/json' -d @<(jq -n --arg u "$1" '{model:"claude-3-5-sonnet-20240620",max_tokens:2000,temperature:0,system:"Respond with JSON only",messages:[{role:"user",content:$u}]}'); }

case "$PROVIDER" in
  openai)
    [[ -z "${OPENAI_API_KEY:-}" ]] && { echo "OPENAI_API_KEY not set"; exit 1; }
    openai_json "$extract_prompt" | tee kb_extract.json >/dev/null
    openai_json "$graph_prompt" | jq . > source_graph.json
    curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
      -d @<(jq -n --arg m "${OPENAI_MODEL:-gpt-4o-mini}" --arg u "$plan_prompt" '{model:$m,temperature:0,messages:[{role:"user",content:$u}]}') \
      | jq -r '.choices[0].message.content' > kb_update_plan.md
    ;;
  azure)
    azure_json "$extract_prompt" | tee kb_extract.json >/dev/null
    azure_json "$graph_prompt" | jq . > source_graph.json
    curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
      -H "api-key: $AZURE_OPENAI_KEY" -H 'Content-Type: application/json' \
      -d @<(jq -n --arg u "$plan_prompt" '{temperature:0,messages:[{role:"user",content:$u}]}') \
      | jq -r '.choices[0].message.content' > kb_update_plan.md
    ;;
  anthropic)
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && { echo "ANTHROPIC_API_KEY not set"; exit 1; }
    anthropic_json "$extract_prompt" | tee kb_extract.json >/dev/null
    anthropic_json "$graph_prompt" | jq . > source_graph.json
    curl -s https://api.anthropic.com/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H 'Content-Type: application/json' \
      -d @<(jq -n --arg u "$plan_prompt" '{model:"claude-3-5-sonnet-20240620",max_tokens:2000,temperature:0,messages:[{role:"user",content:$u}]}') \
      | jq -r '.content[0].text' > kb_update_plan.md
    ;;
  *) echo "Unknown provider: $PROVIDER"; exit 1 ;;
esac

jq '.entities' kb_extract.json > kb_entities.json
jq '.relations' kb_extract.json > kb_relations.json
echo "Done: kb_entities.json kb_relations.json source_graph.json kb_update_plan.md"

