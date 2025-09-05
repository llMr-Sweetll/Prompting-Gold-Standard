# Quickstart: Local RAG → Eval → Doc with Ollama

Run the RAG → rubric evaluation → brief generation flow entirely locally via [Ollama](https://ollama.com). Outputs:
- `rag_answer.md`
- `evaluation.json`
- `research_brief.md`

Tested with models like `llama3.1` and `mistral-nemo`. Ensure `ollama serve` is running at `http://localhost:11434` and models are pulled.

## 0) Context and Question
```bash
cat > context.txt <<'EOF'
[#A] 2021 Journal: task roles improve, collaboration roles decline
[#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
EOF
echo 'Summarize productivity impacts of remote work across roles and note uncertainties.' > question.txt
```

## 1) RAG Answer (Ollama Chat API)
```bash
MODEL=${OLLAMA_MODEL:-llama3.1}
SYSTEM='You are rigorous; use ONLY provided context; cite [#id]; do not guess.'
USER=$(cat <<'EOT'
Context (---):
---
$(cat context.txt)
---
Question:
$(cat question.txt)
EOT
)

curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$MODEL" --arg s "$SYSTEM" --arg u "$USER" '{
  model:$m,
  messages:[ {role:"system",content:$s},{role:"user",content:$u} ],
  stream:false
}') | jq -r '.message.content' | tee rag_answer.md
```

## 2) Rubric Evaluation (JSON)
```bash
MODEL=${OLLAMA_MODEL:-llama3.1}
PROMPT=$(cat <<'EOT'
Evaluate the following answer. Return JSON with fields: score (0-5), criteria {accuracy, completeness, clarity, integrity, actionability} each with score and notes, and issues [{type, span, fix}].
Answer:
<<<
EOT
)

curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$MODEL" --arg p "${PROMPT}$(cat rag_answer.md)
>>>" '{
  model:$m, messages:[{role:"user",content:$p}], stream:false
}') | jq -r '.message.content' | tee evaluation.json
```

## 3) Research Brief
```bash
MODEL=${OLLAMA_MODEL:-llama3.1}
PROMPT=$(cat <<'EOT'
Write a 1-page research brief using the Answer below. Sections: Context & Question, Evidence ([#id] citations), Uncertainties, Practical Implications.
Answer:
<<<
EOT
)

curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$MODEL" --arg p "${PROMPT}$(cat rag_answer.md)
>>>" '{
  model:$m, messages:[{role:"user",content:$p}], stream:false
}') | jq -r '.message.content' | tee research_brief.md
```

## Notes
- Local models vary; consider using smaller prompts or enabling 4-bit quantization for speed.
- For reproducibility, pin model hashes and document system prompts in your repo.

## One-Block End-to-End (Ollama)
```bash
set -euo pipefail
MODEL=${OLLAMA_MODEL:-llama3.1}
cat > context.txt <<'EOF'
[#A] 2021 Journal: task roles improve, collaboration roles decline
[#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
EOF
echo 'Summarize productivity impacts of remote work across roles and note uncertainties.' > question.txt
SYSTEM='You are rigorous; use ONLY provided context; cite [#id]; do not guess.'
USER=$(cat <<'EOT'
Context (---):
---
$(cat context.txt)
---
Question:
$(cat question.txt)
EOT
)
curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$MODEL" --arg s "$SYSTEM" --arg u "$USER" '{model:$m,messages:[{role:"system",content:$s},{role:"user",content:$u}],stream:false}') | jq -r '.message.content' | tee rag_answer.md
EVAL=$(cat <<'EOT'
Evaluate the following answer. Return JSON with fields: score (0-5), criteria {accuracy, completeness, clarity, integrity, actionability} each with score and notes, and issues [{type, span, fix}].
Answer:
<<<
EOT
)
curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$MODEL" --arg p "${EVAL}$(cat rag_answer.md)
>>>" '{model:$m,messages:[{role:"user",content:$p}],stream:false}') | jq -r '.message.content' | tee evaluation.json
BRIEF=$(cat <<'EOT'
Write a 1-page research brief using the Answer below. Sections: Context & Question, Evidence ([#id] citations), Uncertainties, Practical Implications.
Answer:
<<<
EOT
)
curl -s http://localhost:11434/api/chat -d @<(jq -n --arg m "$MODEL" --arg p "${BRIEF}$(cat rag_answer.md)
>>>" '{model:$m,messages:[{role:"user",content:$p}],stream:false}') | jq -r '.message.content' | tee research_brief.md
echo 'Done: rag_answer.md, evaluation.json, research_brief.md'
```
