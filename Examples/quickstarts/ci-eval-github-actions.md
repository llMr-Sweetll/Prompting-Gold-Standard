# Quickstart: CI Evaluation with GitHub Actions

Add rubric-based evaluation to CI to catch regressions in accuracy/integrity. Produces JSON artifacts and fails the build if thresholds are not met.

References: `JSON-Schemas/prompt-eval-rubric.json`, `Examples/rubrics.md`, `Examples/quickstarts/rag-rubric-docs.md`.

## 0) Action Workflow (copy to .github/workflows/prompt-eval.yml)
```yaml
name: Prompt Evaluation
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install tools
        run: sudo apt-get update && sudo apt-get install -y jq bc
      - name: Prepare prompts
        run: |
          echo "Summarize impacts of remote work by role." > question.txt
          cat <<'EOF' > context.txt
          [#A] 2021 Journal: task roles improve, collaboration roles decline
          [#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
          EOF
      - name: RAG answer (OpenAI)
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          MODEL=${OPENAI_MODEL:-gpt-4o-mini}
          SYS='You are rigorous; use ONLY provided context; cite [#id]; do not guess.'
          USR=$(cat <<'EOT'
          Context (---):
          ---
          $(cat context.txt)
          ---
          Question:
          $(cat question.txt)
          EOT
          )
          curl -s https://api.openai.com/v1/chat/completions \
            -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
            -d @<(jq -n --arg m "$MODEL" --arg s "$SYS" --arg u "$USR" '{model:$m,temperature:0,messages:[{role:"system",content:$s},{role:"user",content:$u}] }') \
            | jq -r '.choices[0].message.content' > rag_answer.md
      - name: Evaluate answer (JSON)
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          MODEL=${OPENAI_MODEL:-gpt-4o-mini}
          PROMPT=$(cat <<'EOT'
          Evaluate the following answer against JSON-Schemas/prompt-eval-rubric.json and return JSON only.
          Answer:
          <<<
          EOT
          )
          curl -s https://api.openai.com/v1/chat/completions \
            -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
            -d @<(jq -n --arg m "$MODEL" --arg p "${PROMPT}$(cat rag_answer.md)
          >>>" '{model:$m,temperature:0,messages:[{role:"user",content:$p}],response_format:{type:"json_object"}}') \
            | tee evaluation.json | jq .
      - name: Enforce thresholds
        run: |
          SCORE=$(jq '.score' evaluation.json)
          ACC=$(jq '.criteria.accuracy.score' evaluation.json)
          INTEG=$(jq '.criteria.integrity.score' evaluation.json)
          echo "Score: $SCORE Accuracy: $ACC Integrity: $INTEG"
          if [ "$(echo "$SCORE < 3.5" | bc -l)" -eq 1 ] || [ "$(echo "$ACC < 4" | bc -l)" -eq 1 ] || [ "$(echo "$INTEG < 4" | bc -l)" -eq 1 ]; then
            echo 'Thresholds not met'; exit 1; fi
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: rag-eval
          path: |
            rag_answer.md
            evaluation.json
```

## 1) Notes
- Wire this into PRs to review changes to prompts/config.
- Extend with dataset-specific golden answers for regression testing.
