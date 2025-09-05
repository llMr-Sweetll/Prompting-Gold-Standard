#!/usr/bin/env bash
set -euo pipefail

# RAG -> Rubric Eval -> Research Brief
# Usage examples:
#   ./run_rag.sh --provider=openai --model=gpt-4o-mini
#   ./run_rag.sh --provider=anthropic
#   ./run_rag.sh --provider=azure
#   ./run_rag.sh --provider=ollama --model=llama3.1
#   ./run_rag.sh --provider=openai --context=ctx.txt --question=q.txt

usage() {
  cat <<USAGE
run_rag.sh --provider=openai|anthropic|azure|ollama [--model=NAME] [--context=FILE] [--question=FILE]

Produces:
  - rag_answer.md      (grounded, cited answer)
  - evaluation.json    (rubric-scored JSON)
  - research_brief.md  (polished brief)

Env vars by provider:
  openai:   OPENAI_API_KEY [OPENAI_MODEL]
  azure:    AZURE_OPENAI_KEY, AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_DEPLOYMENT, AZURE_OPENAI_API_VERSION
  anthropic: ANTHROPIC_API_KEY
  ollama:   (local http://localhost:11434) [OLLAMA_MODEL]
USAGE
  exit 1
}

need() { command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need curl; need jq

PROVIDER="openai"
MODEL=""
CTX_FILE=""
Q_FILE=""

for arg in "$@"; do
  case "$arg" in
    --provider=*) PROVIDER="${arg#*=}" ;;
    --model=*) MODEL="${arg#*=}" ;;
    --context=*) CTX_FILE="${arg#*=}" ;;
    --question=*) Q_FILE="${arg#*=}" ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $arg"; usage ;;
  esac
done

# Defaults: create sample context/question if not provided
if [[ -z "${CTX_FILE}" ]]; then
  CTX_FILE="context.txt"
  cat >"${CTX_FILE}" <<'EOF'
[#A] 2021 Journal: task roles improve, collaboration roles decline
[#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
EOF
fi

if [[ -z "${Q_FILE}" ]]; then
  Q_FILE="question.txt"
  echo 'Summarize productivity impacts of remote work across roles and note uncertainties.' >"${Q_FILE}"
fi

SYSTEM=$(cat <<'SYS'
You are a rigorous research assistant.
Rules:
- Use ONLY the provided context.
- Cite evidence inline with [#doc-id] and quotes.
- If context is insufficient, say "Insufficient evidence" and list missing info.
- Do not guess; no external knowledge unless allowed.
Output sections:
- Answer (2–5 sentences)
- Evidence (bullets: [#doc-id] + quoted spans)
- Open Questions (if any)
SYS
)

USER=$(cat <<USR
Context (---):
---
$(cat "$CTX_FILE")
---

Question:
$(cat "$Q_FILE")
USR
)

# Provider-specific helpers
call_openai() {
  local messages_json="$1"; local respfmt="$2"; local temperature="${3:-0}";
  local model="${MODEL:-${OPENAI_MODEL:-gpt-4o-mini}}"
  [[ -z "${OPENAI_API_KEY:-}" ]] && { echo "OPENAI_API_KEY not set"; exit 1; }
  curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
    -d @<(jq -n --argjson msgs "$messages_json" --arg m "$model" --argjson rf "$respfmt" --argjson t "$temperature" '{
      model: $m, temperature: (t|tonumber), messages: $msgs
    } + (rf // {}))
}

call_azure() {
  local messages_json="$1"; local respfmt="$2"; local temperature="${3:-0}";
  [[ -z "${AZURE_OPENAI_KEY:-}" || -z "${AZURE_OPENAI_ENDPOINT:-}" || -z "${AZURE_OPENAI_DEPLOYMENT:-}" || -z "${AZURE_OPENAI_API_VERSION:-}" ]] && {
    echo "Missing Azure OpenAI env vars"; exit 1; }
  curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
    -H "api-key: $AZURE_OPENAI_KEY" -H "Content-Type: application/json" \
    -d @<(jq -n --argjson msgs "$messages_json" --argjson rf "$respfmt" --argjson t "$temperature" '{
      temperature: (t|tonumber), messages: $msgs
    } + (rf // {}))
}

call_anthropic() {
  local system="$1"; local user="$2"; local json_only="$3"; local temperature="${4:-0}";
  [[ -z "${ANTHROPIC_API_KEY:-}" ]] && { echo "ANTHROPIC_API_KEY not set"; exit 1; }
  local sys_full="$system"; [[ "$json_only" == "1" ]] && sys_full+=$'\nRespond with JSON only.'
  curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -d @<(jq -n --arg s "$sys_full" --arg u "$user" --arg m "claude-3-5-sonnet-20240620" --argjson t "$temperature" '{
      model: $m, max_tokens: 2000, temperature: (t|tonumber), system: $s, messages: [ {role:"user", content:$u} ]
    }')
}

call_ollama() {
  local system="$1"; local user="$2";
  local model="${MODEL:-${OLLAMA_MODEL:-llama3.1}}"
  curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$model" --arg s "$system" --arg u "$user" '{
    model:$m, messages:[ {role:"system",content:$s},{role:"user",content:$u} ], stream:false
  }')
}

# Step 1: RAG Answer
case "$PROVIDER" in
  openai)
    MESSAGES=$(jq -n --arg s "$SYSTEM" --arg u "$USER" '[{"role":"system","content":$s},{"role":"user","content":$u}]')
    call_openai "$MESSAGES" 'null' 0 | jq -r '.choices[0].message.content' > rag_answer.md
    ;;
  azure)
    MESSAGES=$(jq -n --arg s "$SYSTEM" --arg u "$USER" '[{"role":"system","content":$s},{"role":"user","content":$u}]')
    call_azure "$MESSAGES" 'null' 0 | jq -r '.choices[0].message.content' > rag_answer.md
    ;;
  anthropic)
    call_anthropic "$SYSTEM" "$USER" 0 0 | jq -r '.content[0].text' > rag_answer.md
    ;;
  ollama)
    call_ollama "$SYSTEM" "$USER" | jq -r '.message.content' > rag_answer.md
    ;;
  *) echo "Unknown provider: $PROVIDER"; exit 1 ;;
esac
echo "Wrote rag_answer.md"

# Step 2: Evaluation JSON (rubric)
EVAL_PROMPT=$(cat <<EOT
Evaluate the following answer against JSON-Schemas/prompt-eval-rubric.json and return JSON only.
Answer:
<<<
$(cat rag_answer.md)
>>>
EOT
)

case "$PROVIDER" in
  openai)
    MESSAGES=$(jq -n --arg u "$EVAL_PROMPT" '[{"role":"user","content":$u}]')
    call_openai "$MESSAGES" '{"response_format": {"type":"json_object"}}' 0 | jq -r '.choices[0].message.content' > evaluation.json
    ;;
  azure)
    MESSAGES=$(jq -n --arg u "$EVAL_PROMPT" '[{"role":"user","content":$u}]')
    call_azure "$MESSAGES" '{"response_format": {"type":"json_object"}}' 0 | jq -r '.choices[0].message.content' > evaluation.json
    ;;
  anthropic)
    call_anthropic "Respond with JSON only." "$EVAL_PROMPT" 1 0 | jq -r '.content[0].text' > evaluation.json
    ;;
  ollama)
    curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "${MODEL:-${OLLAMA_MODEL:-llama3.1}}" --arg u "$EVAL_PROMPT" '{model:$m, messages:[{role:"user",content:$u}], stream:false}') \
      | jq -r '.message.content' > evaluation.json
    ;;
esac
echo "Wrote evaluation.json"

# Step 3: Research Brief
BRIEF_PROMPT=$(cat <<EOT
Write a 1-page research brief:
- Context and question
- What the evidence says (with [#doc-id] citations)
- Uncertainties and gaps
- Practical implications
Tone: concise, neutral, non-speculative. Use content from the Answer below.
Answer:
<<<
$(cat rag_answer.md)
>>>
EOT
)

case "$PROVIDER" in
  openai)
    MESSAGES=$(jq -n --arg u "$BRIEF_PROMPT" '[{"role":"user","content":$u}]')
    call_openai "$MESSAGES" 'null' 0.2 | jq -r '.choices[0].message.content' > research_brief.md
    ;;
  azure)
    MESSAGES=$(jq -n --arg u "$BRIEF_PROMPT" '[{"role":"user","content":$u}]')
    call_azure "$MESSAGES" 'null' 0.2 | jq -r '.choices[0].message.content' > research_brief.md
    ;;
  anthropic)
    call_anthropic "" "$BRIEF_PROMPT" 0 0.2 | jq -r '.content[0].text' > research_brief.md
    ;;
  ollama)
    curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "${MODEL:-${OLLAMA_MODEL:-llama3.1}}" --arg u "$BRIEF_PROMPT" '{model:$m, messages:[{role:"user",content:$u}], stream:false}') \
      | jq -r '.message.content' > research_brief.md
    ;;
esac
echo "Done: rag_answer.md evaluation.json research_brief.md"

