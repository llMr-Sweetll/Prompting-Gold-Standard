# Quickstart: Business Intelligence Suite (Market Analysis → Competitive Intelligence → Strategy Reports)

Complete business intelligence workflow for market research, competitive analysis, and strategic planning. Produces:
- `market_analysis.json` (comprehensive market assessment)
- `competitive_intelligence.md` (competitor analysis with SWOT)
- `strategic_recommendations.pdf` (executive strategy report)
- `roi_projections.xlsx` (financial projections and ROI analysis)

References: `Applications/market-surveys.md`, `Guides/retrieval-augmented-generation.md`, `JSON-Schemas/data-analysis-report.json`.

## 0) Business Context Setup
```bash
cat > business_context.txt <<'EOF'
Industry: Electric Vehicle Market
Company: Startup EV manufacturer
Target Market: Urban commuters aged 25-45
Geographic Focus: North America and Europe
Time Horizon: 3 years
Investment Available: $50M Series A
Current Products: Entry-level electric scooters and bikes
EOF

echo 'Business Objective: Expand into passenger EV market with affordable, urban-focused vehicles' > business_objective.txt
```

PowerShell alternative:
```powershell
@'
Industry: Electric Vehicle Market
Company: Startup EV manufacturer
Target Market: Urban commuters aged 25-45
Geographic Focus: North America and Europe
Time Horizon: 3 years
Investment Available: $50M Series A
Current Products: Entry-level electric scooters and bikes
'@ | Set-Content business_context.txt

@'Business Objective: Expand into passenger EV market with affordable, urban-focused vehicles'@ | Set-Content business_objective.txt
```

## 1) Market Analysis (Data-Driven Insights)
```
Generate comprehensive market analysis with statistical validation.
```

### Bash (OpenAI with Schema Validation)
```bash
SCHEMA=$(cat Prompting-Gold-Standard/JSON-Schemas/data-analysis-report.json)

SYSTEM='Generate market analysis as valid JSON matching the provided schema. Include market size, growth rates, segmentation, and statistical projections.'

USER=$(cat <<'USR'
Business Context:
$(cat business_context.txt)

Objective:
$(cat business_objective.txt)

Analyze market covering:
- Total addressable market (TAM) calculation
- Serviceable addressable market (SAM) assessment
- Market growth trends and projections
- Customer segmentation and personas
- Competitive landscape overview
- Regulatory and economic factors
- Technology adoption curves
USR
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg schema "$SCHEMA" --arg sys "$SYSTEM" --arg usr "$USER" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.1,
    messages: [
      {role:"system", content:"Schema: \($schema)\n\n\($sys)"},
      {role:"user", content:$usr}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee market_analysis.json

# Validate against schema
if command -v python3 &> /dev/null; then
  python3 -c "
import json, jsonschema
with open('market_analysis.json') as f:
  data = json.load(f)
with open('Prompting-Gold-Standard/JSON-Schemas/data-analysis-report.json') as f:
  schema = json.load(f)
jsonschema.validate(data, schema)
print('✅ Schema validation passed')
"
fi
```

### PowerShell (OpenAI)
```powershell
$SCHEMA = Get-Content -Raw 'Prompting-Gold-Standard/JSON-Schemas/data-analysis-report.json'

$SYSTEM = 'Generate market analysis as valid JSON matching the provided schema. Include market size, growth rates, segmentation, and statistical projections.'

$USER = @"
Business Context:
$(Get-Content -Raw business_context.txt)

Objective:
$(Get-Content -Raw business_objective.txt)

Analyze market covering:
- Total addressable market (TAM) calculation
- Serviceable addressable market (SAM) assessment
- Market growth trends and projections
- Customer segmentation and personas
- Competitive landscape overview
- Regulatory and economic factors
- Technology adoption curves
"@

$body = @{
  model = $env:OPENAI_MODEL; temperature = 0.1;
  messages = @(
    @{role='system';content="Schema: $SCHEMA`n`n$SYSTEM"},
    @{role='user';content=$USER}
  )
} | ConvertTo-Json -Depth 10

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content -Path market_analysis.json -Value $resp.choices[0].message.content
```

## 2) Competitive Intelligence Analysis
```
Create detailed competitor analysis with SWOT and strategic positioning.
```

### Bash (OpenAI)
```bash
SYSTEM='Generate comprehensive competitive intelligence analysis. Include SWOT analysis, strategic positioning, product comparisons, and market share analysis.'

COMPETITIVE_PROMPT=$(cat <<'EOT'
Market Analysis:
$(cat market_analysis.json)

Business Context:
$(cat business_context.txt)

Analyze competition covering:
1. Key competitors identification and profiling
2. Product and feature comparison matrix
3. Pricing and positioning analysis
4. SWOT analysis for each major competitor
5. Market share and growth trajectory
6. Strategic moves and partnerships
7. Potential threats and opportunities
8. Competitive advantages assessment
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg prompt "$COMPETITIVE_PROMPT" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.2,
    messages: [
      {role:"system", content:$sys},
      {role:"user", content:$prompt}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee competitive_intelligence.md
```

## 3) Strategic Recommendations Report
```
Generate executive-level strategic recommendations with implementation roadmap.
```

### Bash (OpenAI)
```bash
SYSTEM='Create executive strategic recommendations report. Include market entry strategy, product positioning, go-to-market plan, and financial projections.'

STRATEGY_PROMPT=$(cat <<'EOT'
Market Analysis:
$(cat market_analysis.json)

Competitive Intelligence:
$(cat competitive_intelligence.md)

Business Context:
$(cat business_context.txt)

Generate strategic recommendations covering:
1. Executive Summary
2. Market Opportunity Assessment
3. Competitive Positioning Strategy
4. Product Development Roadmap
5. Go-to-Market Strategy
6. Marketing and Sales Plan
7. Operations and Supply Chain Strategy
8. Financial Projections (3-year)
9. Risk Assessment and Mitigation
10. Implementation Timeline and Milestones
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg prompt "$STRATEGY_PROMPT" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.1,
    messages: [
      {role:"system", content:$sys},
      {role:"user", content:$prompt}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee strategic_recommendations.md
```

## 4) ROI and Financial Projections
```
Create detailed financial projections with sensitivity analysis.
```

### Bash (OpenAI)
```bash
SYSTEM='Generate detailed ROI analysis and financial projections. Include revenue projections, cost analysis, break-even analysis, and sensitivity testing.'

FINANCIAL_PROMPT=$(cat <<'EOT'
Strategic Recommendations:
$(cat strategic_recommendations.md)

Business Context:
$(cat business_context.txt)

Investment Available: $50M

Create financial analysis covering:
1. Revenue Projections (3-year)
   - Unit sales forecasts
   - Pricing strategy and ASP
   - Market penetration rates
   - Revenue growth trajectory

2. Cost Structure Analysis
   - Product development costs
   - Manufacturing and supply chain
   - Marketing and sales expenses
   - Operational overhead

3. Profitability Analysis
   - Gross margin projections
   - Operating expense breakdown
   - EBITDA and net income
   - Break-even analysis

4. ROI and Investment Returns
   - NPV and IRR calculations
   - Payback period analysis
   - Return on investment metrics

5. Sensitivity Analysis
   - Best/worst case scenarios
   - Key risk factor impact
   - Monte Carlo simulation setup

6. Funding Requirements
   - Capital expenditure needs
   - Working capital requirements
   - Additional funding rounds
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg prompt "$FINANCIAL_PROMPT" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.1,
    messages: [
      {role:"system", content:$sys},
      {role:"user", content:$prompt}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee financial_projections.md
```

## 5) One-Block End-to-End BI Suite
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o}

# Setup business context
cat > business_context.txt <<'EOF'
Industry: Electric Vehicle Market
Company: Startup EV manufacturer
Target Market: Urban commuters aged 25-45
Geographic Focus: North America and Europe
Time Horizon: 3 years
Investment Available: $50M Series A
Current Products: Entry-level electric scooters and bikes
EOF

echo 'Business Objective: Expand into passenger EV market with affordable, urban-focused vehicles' > business_objective.txt

# Generate market analysis
SCHEMA=$(cat Prompting-Gold-Standard/JSON-Schemas/data-analysis-report.json)
SYSTEM='Generate market analysis as valid JSON matching the provided schema. Include market size, growth rates, segmentation, and statistical projections.'

USER=$(cat <<'EOT'
Business Context:
$(cat business_context.txt)

Objective:
$(cat business_objective.txt)

Analyze market covering:
- Total addressable market (TAM) calculation
- Serviceable addressable market (SAM) assessment
- Market growth trends and projections
- Customer segmentation and personas
- Competitive landscape overview
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SYSTEM" --arg u "$USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$u}]
  }') | jq -r '.choices[0].message.content' | tee market_analysis.json

# Generate competitive intelligence
COMP_SYSTEM='Generate comprehensive competitive intelligence analysis. Include SWOT analysis, strategic positioning, product comparisons, and market share analysis.'

COMP_PROMPT=$(cat <<'EOT'
Market Analysis:
$(cat market_analysis.json)

Business Context:
$(cat business_context.txt)

Analyze competition covering:
1. Key competitors identification and profiling
2. Product and feature comparison matrix
3. SWOT analysis for each major competitor
4. Strategic moves and partnerships
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$COMP_SYSTEM" --arg p "$COMP_PROMPT" '{
    model:$m, temperature:0.2,
    messages:[{role:"system",content:$s},{role:"user",content:$p}]
  }') | jq -r '.choices[0].message.content' | tee competitive_intelligence.md

# Generate strategic recommendations
STRATEGY_SYSTEM='Create executive strategic recommendations report. Include market entry strategy, product positioning, go-to-market plan, and financial projections.'

STRATEGY_PROMPT=$(cat <<'EOT'
Market Analysis:
$(cat market_analysis.json)

Competitive Intelligence:
$(cat competitive_intelligence.md)

Business Context:
$(cat business_context.txt)

Generate strategic recommendations covering:
1. Executive Summary
2. Market Opportunity Assessment
3. Competitive Positioning Strategy
4. Go-to-Market Strategy
5. Implementation Timeline and Milestones
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$STRATEGY_SYSTEM" --arg p "$STRATEGY_PROMPT" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$p}]
  }') | jq -r '.choices[0].message.content' | tee strategic_recommendations.md

# Generate financial projections
FINANCIAL_SYSTEM='Generate detailed ROI analysis and financial projections. Include revenue projections, cost analysis, break-even analysis, and sensitivity testing.'

FINANCIAL_PROMPT=$(cat <<'EOT'
Strategic Recommendations:
$(cat strategic_recommendations.md)

Business Context:
$(cat business_context.txt)

Investment Available: $50M

Create financial analysis covering:
1. Revenue Projections (3-year)
2. Cost Structure Analysis
3. Profitability Analysis
4. ROI and Investment Returns
5. Sensitivity Analysis
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$FINANCIAL_SYSTEM" --arg p "$FINANCIAL_PROMPT" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$p}]
  }') | jq -r '.choices[0].message.content' | tee financial_projections.md

echo '🎉 Business Intelligence Suite Complete!'
echo 'Generated files: market_analysis.json, competitive_intelligence.md, strategic_recommendations.md, financial_projections.md'
```

## Notes
- This BI suite provides comprehensive business intelligence for strategic decision-making
- JSON schema validation ensures market analysis quality and consistency
- Competitive intelligence includes actionable SWOT analysis and positioning insights
- Financial projections include sensitivity analysis and risk assessment
- Strategic recommendations provide clear implementation roadmap and milestones
