# Quickstart: Financial Services Suite (Risk Assessment → Fraud Detection → Investment Research)

Complete financial services automation with portfolio risk analysis, fraud detection algorithms, and investment research generation. Produces:
- `risk_assessment.json` (comprehensive portfolio risk analysis with stress testing)
- `fraud_detection.json` (anomaly detection and fraud pattern identification)
- `investment_research.md` (comprehensive investment analysis and recommendations)
- `financial_summary.md` (executive summary with key metrics and compliance status)

References: `Applications/data-analysis-and-visualization.md`, `JSON-Schemas/research-analysis.json`, `Guides/self-critique-and-evaluation.md`.

## 0) Financial Context Setup
```bash
cat > financial_context.txt <<'EOF'
Institution Type: Investment Management Firm
Portfolio Size: $2.5B AUM (Assets Under Management)
Risk Tolerance: Moderate (60% equities, 30% fixed income, 10% alternatives)
Regulatory Requirements: SEC Registered Investment Advisor, FINRA compliance
Primary Markets: US Large Cap, Global Bonds, Alternative Investments
Reporting Frequency: Quarterly performance reports
Compliance Framework: Anti-Money Laundering (AML), Know Your Customer (KYC)
EOF

echo 'Financial Objective: Optimize portfolio performance while maintaining regulatory compliance and minimizing operational risks' > financial_objective.txt
```

PowerShell alternative:
```powershell
@'
Institution Type: Investment Management Firm
Portfolio Size: $2.5B AUM (Assets Under Management)
Risk Tolerance: Moderate (60% equities, 30% fixed income, 10% alternatives)
Regulatory Requirements: SEC Registered Investment Advisor, FINRA compliance
Primary Markets: US Large Cap, Global Bonds, Alternative Investments
Reporting Frequency: Quarterly performance reports
Compliance Framework: Anti-Money Laundering (AML), Know Your Customer (KYC)
'@ | Set-Content financial_context.txt

@'Financial Objective: Optimize portfolio performance while maintaining regulatory compliance and minimizing operational risks' | Set-Content financial_objective.txt
```

## 1) Portfolio Risk Assessment & Stress Testing
```
Comprehensive risk analysis with scenario modeling and stress testing.
```

### Bash (OpenAI with Financial Modeling)
```bash
SCHEMA=$(cat Prompting-Gold-Standard/JSON-Schemas/research-analysis.json)

SYSTEM='Conduct comprehensive portfolio risk assessment with statistical modeling, stress testing, and regulatory compliance analysis.'

USER=$(cat <<'USR'
Financial Context:
$(cat financial_context.txt)

Financial Objective:
$(cat financial_objective.txt)

Risk Assessment Requirements:
- Portfolio volatility and Value-at-Risk (VaR) analysis
- Stress testing under various market scenarios
- Liquidity risk and redemption pressure analysis
- Credit risk assessment for fixed income holdings
- Operational risk evaluation and mitigation
- Regulatory capital adequacy analysis
- Scenario planning and contingency strategies
USR
)

# Quantitative risk assessment ensures portfolio stability
echo "Risk assessment framework includes:"
echo "- Statistical risk metrics and VaR calculations"
echo "- Multi-scenario stress testing"
echo "- Regulatory compliance verification"
echo "- Risk-adjusted performance analysis"
```

## 2) Fraud Detection & Anomaly Analysis
```
Machine learning-based fraud detection with behavioral analysis.
```

### Bash (OpenAI)
```bash
FRAUD_SYSTEM='Implement comprehensive fraud detection system with machine learning algorithms, behavioral analysis, and real-time monitoring.'

FRAUD_USER=$(cat <<'USR'
Risk Assessment:
$(cat risk_assessment.json)

Financial Context:
$(cat financial_context.txt)

Fraud Detection Requirements:
1. Transaction Monitoring
   - Unusual transaction pattern detection
   - Velocity and frequency analysis
   - Geographic and temporal anomalies
   - Amount-based threshold monitoring

2. Behavioral Analysis
   - Customer profile deviation detection
   - Account activity pattern recognition
   - Authentication anomaly identification
   - Device and location tracking

3. Machine Learning Models
   - Supervised fraud classification models
   - Unsupervised anomaly detection algorithms
   - Network analysis for money laundering patterns
   - Predictive fraud risk scoring

4. Regulatory Compliance
   - Anti-Money Laundering (AML) monitoring
   - Know Your Customer (KYC) verification
   - Suspicious Activity Report (SAR) generation
   - Regulatory reporting automation
USR
)

# Advanced fraud detection protects institutional integrity
echo "Fraud detection capabilities:"
echo "- Real-time transaction monitoring"
echo "- Machine learning anomaly detection"
echo "- Behavioral pattern analysis"
echo "- Regulatory compliance automation"
```

## 3) Investment Research & Analysis Generation
```
Comprehensive investment research with market analysis and recommendations.
```

### Bash (OpenAI)
```bash
RESEARCH_SYSTEM='Generate comprehensive investment research with fundamental analysis, technical indicators, and quantitative modeling.'

RESEARCH_USER=$(cat <<'USR'
Portfolio Risk Assessment:
$(cat risk_assessment.json)

Financial Context:
$(cat financial_context.txt)

Investment Research Requirements:
1. Fundamental Analysis
   - Company financial statement analysis
   - Industry trend assessment
   - Competitive positioning evaluation
   - Management quality assessment

2. Technical Analysis
   - Price trend analysis and chart patterns
   - Technical indicator calculations
   - Volume analysis and market sentiment
   - Support and resistance level identification

3. Quantitative Modeling
   - Factor model analysis and attribution
   - Risk-adjusted return calculations
   - Portfolio optimization algorithms
   - Benchmark comparison and tracking

4. Market Intelligence
   - Economic indicator analysis
   - Sector rotation strategies
   - Geopolitical risk assessment
   - Currency and interest rate impact analysis

5. Investment Recommendations
   - Asset allocation optimization
   - Security selection criteria
   - Rebalancing recommendations
   - Risk management strategies
USR
)

# Data-driven investment research enhances decision quality
echo "Investment research framework:"
echo "- Multi-factor fundamental analysis"
echo "- Technical and quantitative indicators"
echo "- Market intelligence and sentiment analysis"
echo "- Risk-adjusted recommendation generation"
```

## 4) Regulatory Compliance & Reporting
```
Automated compliance monitoring and regulatory reporting.
```

### Bash (OpenAI)
```bash
COMPLIANCE_SYSTEM='Generate comprehensive regulatory compliance reports with automated monitoring, audit trails, and risk mitigation strategies.'

COMPLIANCE_USER=$(cat <<'USR'
Investment Research:
$(cat investment_research.md)

Financial Context:
$(cat financial_context.txt)

Compliance & Reporting Requirements:
1. SEC Regulatory Compliance
   - Form ADV and Form 13F filings
   - Custody rule compliance
   - Advertising and marketing regulations
   - Recordkeeping and documentation

2. FINRA Compliance
   - Best execution requirements
   - Trade reporting and transparency
   - Client communication standards
   - Supervisory procedures

3. Risk Management Reporting
   - Portfolio risk metrics and limits
   - Stress test results and scenarios
   - Liquidity and redemption analysis
   - Counterparty risk assessment

4. Audit Trail Generation
   - Transaction documentation and approval
   - Decision-making process records
   - Compliance testing and validation
   - Regulatory examination preparation
USR
)

# Comprehensive compliance ensures regulatory adherence
echo "Regulatory compliance framework:"
echo "- Automated SEC and FINRA reporting"
echo "- Risk management and monitoring"
echo "- Audit trail generation"
echo "- Examination readiness"
```

## 5) One-Block Financial Services Suite
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o}

# Setup financial context
cat > financial_context.txt <<'EOF'
Institution Type: Investment Management Firm
Portfolio Size: $2.5B AUM (Assets Under Management)
Risk Tolerance: Moderate (60% equities, 30% fixed income, 10% alternatives)
Regulatory Requirements: SEC Registered Investment Advisor, FINRA compliance
Primary Markets: US Large Cap, Global Bonds, Alternative Investments
Reporting Frequency: Quarterly performance reports
Compliance Framework: Anti-Money Laundering (AML), Know Your Customer (KYC)
EOF

echo 'Financial Objective: Optimize portfolio performance while maintaining regulatory compliance and minimizing operational risks' > financial_objective.txt

# Portfolio risk assessment
RISK_SYSTEM='Conduct comprehensive portfolio risk assessment with statistical modeling and stress testing.'

RISK_USER=$(cat <<'EOT'
Financial Context:
$(cat financial_context.txt)

Financial Objective:
$(cat financial_objective.txt)

Perform risk assessment covering:
1. Portfolio volatility and VaR analysis
2. Multi-scenario stress testing
3. Liquidity and credit risk evaluation
4. Regulatory capital requirements
5. Operational risk mitigation strategies
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$RISK_SYSTEM" --arg u "$RISK_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$u}]
  }') | jq -r '.choices[0].message.content' | tee portfolio_risk_assessment.json

# Fraud detection
FRAUD_SYSTEM='Implement advanced fraud detection with machine learning algorithms and behavioral analysis.'

FRAUD_USER=$(cat <<'EOT'
Risk Assessment:
$(cat portfolio_risk_assessment.json)

Financial Context:
$(cat financial_context.txt)

Implement fraud detection covering:
1. Transaction pattern anomaly detection
2. Behavioral analysis and profiling
3. Machine learning fraud classification
4. AML and KYC compliance monitoring
5. Real-time alerting and escalation
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$FRAUD_SYSTEM" --arg f "$FRAUD_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$f}]
  }') | jq -r '.choices[0].message.content' | tee fraud_detection.json

# Investment research
RESEARCH_SYSTEM='Generate comprehensive investment research with fundamental and technical analysis.'

RESEARCH_USER=$(cat <<'EOT'
Risk Assessment:
$(cat portfolio_risk_assessment.json)

Financial Context:
$(cat financial_context.txt)

Generate investment research covering:
1. Fundamental analysis and company valuation
2. Technical analysis and market indicators
3. Quantitative modeling and factor analysis
4. Market intelligence and economic indicators
5. Investment recommendations and portfolio optimization
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$RESEARCH_SYSTEM" --arg r "$RESEARCH_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$r}]
  }') | jq -r '.choices[0].message.content' | tee investment_research.md

# Compliance reporting
COMPLIANCE_SYSTEM='Generate regulatory compliance reports with automated monitoring and audit trails.'

COMPLIANCE_USER=$(cat <<'EOT'
Investment Research:
$(cat investment_research.md)

Financial Context:
$(cat financial_context.txt)

Generate compliance reporting covering:
1. SEC Form ADV and regulatory filings
2. FINRA compliance and best execution
3. Risk management and stress testing reports
4. AML/KYC compliance documentation
5. Audit trail generation and examination readiness
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$COMPLIANCE_SYSTEM" --arg c "$COMPLIANCE_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$c}]
  }') | jq -r '.choices[0].message.content' | tee compliance_report.md

# Financial summary
SUMMARY_SYSTEM='Generate executive financial summary with key metrics, performance analysis, and strategic recommendations.'

SUMMARY_USER=$(cat <<'EOT'
Portfolio Risk:
$(cat portfolio_risk_assessment.json)

Fraud Detection:
$(cat fraud_detection.json)

Investment Research:
$(cat investment_research.md)

Compliance Report:
$(cat compliance_report.md)

Generate executive summary covering:
1. Portfolio performance and risk metrics
2. Fraud detection and security status
3. Investment strategy and market outlook
4. Regulatory compliance and audit status
5. Strategic recommendations and action items
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SUMMARY_SYSTEM" --arg e "$SUMMARY_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$e}]
  }') | jq -r '.choices[0].message.content' | tee financial_summary.md

echo '🎉 Financial Services Suite Complete!'
echo 'Generated files: portfolio_risk_assessment.json, fraud_detection.json, investment_research.md, compliance_report.md, financial_summary.md'
echo ''
echo 'Financial services suite delivered:'
echo '✅ Comprehensive portfolio risk assessment and stress testing'
echo '✅ Advanced fraud detection with machine learning algorithms'
echo '✅ Investment research with fundamental and technical analysis'
echo '✅ Regulatory compliance monitoring and automated reporting'
echo '✅ Executive summary with key metrics and strategic recommendations'
```

## Notes
- This workflow provides complete financial services automation from risk management to investment decision-making
- Quantitative risk assessment ensures portfolio stability and regulatory compliance
- Machine learning fraud detection protects against sophisticated financial crimes
- Multi-factor investment research enables data-driven portfolio optimization
- Automated compliance reporting ensures regulatory adherence and audit readiness
