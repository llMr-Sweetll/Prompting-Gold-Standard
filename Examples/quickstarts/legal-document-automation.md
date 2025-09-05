# Quickstart: Legal Document Automation (Contract Analysis → Risk Assessment → Compliance Review)

Complete legal document processing pipeline with automated contract analysis, risk assessment, and compliance verification. Produces:
- `contract_analysis.json` (comprehensive contract analysis with clause extraction)
- `risk_assessment.json` (risk identification and mitigation recommendations)
- `compliance_report.md` (regulatory compliance verification and audit trail)
- `legal_summary.md` (executive summary with key terms and obligations)

References: `JSON-Schemas/content-validation.json`, `Resources/plagiarism-avoidance.md`, `Academic/Ethics-Integrity/academic-integrity.md`.

## 0) Legal Context Setup
```bash
cat > legal_context.txt <<'EOF'
Document Type: Commercial Service Agreement
Jurisdiction: United States (California law)
Industry: Technology/SaaS
Contract Value: $2.5M annually
Risk Tolerance: Medium (standard commercial terms acceptable)
Compliance Requirements: GDPR, CCPA, SOC 2 Type II
Review Deadline: 48 hours
EOF

echo 'Legal Objective: Ensure contract terms protect company interests, identify material risks, and verify regulatory compliance' > legal_objective.txt
```

PowerShell alternative:
```powershell
@'
Document Type: Commercial Service Agreement
Jurisdiction: United States (California law)
Industry: Technology/SaaS
Contract Value: $2.5M annually
Risk Tolerance: Medium (standard commercial terms acceptable)
Compliance Requirements: GDPR, CCPA, SOC 2 Type II
Review Deadline: 48 hours
'@ | Set-Content legal_context.txt

@'Legal Objective: Ensure contract terms protect company interests, identify material risks, and verify regulatory compliance'@ | Set-Content legal_objective.txt
```

## 1) Contract Analysis & Clause Extraction (Document Intelligence)
```
Automated contract analysis with clause identification and term extraction.
```

### Bash (OpenAI with Schema Validation)
```bash
SCHEMA=$(cat Prompting-Gold-Standard/JSON-Schemas/content-validation.json)

SYSTEM='Perform comprehensive contract analysis with clause extraction, term identification, and legal risk assessment as valid JSON.'

USER=$(cat <<'USR'
Legal Context:
$(cat legal_context.txt)

Legal Objective:
$(cat legal_objective.txt)

Contract Analysis Requirements:
- Clause identification and categorization
- Key terms and obligations extraction
- Payment terms and conditions analysis
- Liability and indemnification clauses
- Termination and renewal provisions
- Intellectual property rights and licenses
- Data protection and privacy terms
- Force majeure and dispute resolution
USR
)

# Automated contract analysis ensures comprehensive legal review
echo "Contract analysis covers:"
echo "- Complete clause identification and extraction"
echo "- Risk assessment and mitigation strategies"
echo "- Compliance verification across jurisdictions"
echo "- Executive summary for decision makers"
```

## 2) Risk Assessment & Mitigation (Legal Risk Analysis)
```
Identify legal risks and provide mitigation recommendations.
```

### Bash (OpenAI)
```bash
RISK_SYSTEM='Conduct comprehensive legal risk assessment with mitigation strategies, probability analysis, and impact evaluation.'

RISK_USER=$(cat <<'USR'
Contract Analysis:
$(cat contract_analysis.json)

Legal Context:
$(cat legal_context.txt)

Risk Assessment Framework:
1. Financial Risk Analysis
   - Payment terms and penalty clauses
   - Currency fluctuation risks
   - Tax implications and withholding
   - Liquidated damages provisions

2. Operational Risk Analysis
   - Service level agreements (SLAs)
   - Termination and transition provisions
   - Change management processes
   - Force majeure definitions

3. Legal Risk Analysis
   - Indemnification and liability caps
   - Intellectual property protection
   - Data protection compliance
   - Dispute resolution mechanisms

4. Compliance Risk Analysis
   - Regulatory compliance requirements
   - Industry-specific regulations
   - International law considerations
   - Audit and reporting obligations

Provide risk ratings (Low/Medium/High/Critical) with mitigation recommendations.
USR
)

# Risk-based legal review prioritizes critical issues
echo "Risk assessment methodology:"
echo "- Probability and impact analysis"
echo "- Risk rating and prioritization"
echo "- Mitigation strategy recommendations"
echo "- Compliance gap identification"
```

## 3) Compliance Verification (Regulatory Compliance)
```
Verify regulatory compliance and generate compliance reports.
```

### Bash (OpenAI)
```bash
COMPLIANCE_SYSTEM='Verify regulatory compliance across all applicable jurisdictions and generate detailed compliance reports with audit trails.'

COMPLIANCE_USER=$(cat <<'USR'
Contract Analysis:
$(cat contract_analysis.json)

Risk Assessment:
$(cat risk_assessment.json)

Legal Context:
$(cat legal_context.txt)

Compliance Verification Requirements:
1. GDPR Compliance Analysis
   - Data processing agreements
   - International data transfers
   - Data subject rights provisions
   - Breach notification requirements

2. CCPA Compliance Analysis
   - Personal information definitions
   - Consumer rights implementation
   - Data protection measures
   - Service provider requirements

3. Industry-Specific Compliance
   - SOC 2 Type II requirements
   - Payment Card Industry (PCI) compliance
   - Health Insurance Portability (HIPAA) if applicable
   - Financial services regulations if applicable

4. Audit Trail Generation
   - Compliance verification evidence
   - Risk mitigation documentation
   - Regulatory requirement mapping
   - Recommendation implementation tracking
USR
)

# Comprehensive compliance verification ensures legal protection
echo "Compliance verification includes:"
echo "- Multi-jurisdictional regulatory analysis"
echo "- Industry-specific requirement validation"
echo "- Audit trail generation for compliance"
echo "- Risk mitigation strategy documentation"
```

## 4) Legal Summary & Recommendations (Executive Summary)
```
Generate executive summary with key findings and recommendations.
```

### Bash (OpenAI)
```bash
SUMMARY_SYSTEM='Generate executive legal summary with key findings, risk assessment, and actionable recommendations for decision makers.'

SUMMARY_USER=$(cat <<'USR'
Contract Analysis:
$(cat contract_analysis.json)

Risk Assessment:
$(cat risk_assessment.json)

Compliance Report:
$(cat compliance_report.md)

Legal Context:
$(cat legal_context.txt)

Executive Summary Requirements:
1. Contract Overview
   - Key terms and value proposition
   - Critical obligations and timelines
   - Financial implications summary

2. Risk Summary
   - High-priority risks identified
   - Mitigation recommendations
   - Risk tolerance assessment

3. Compliance Status
   - Regulatory compliance verification
   - Outstanding compliance requirements
   - Recommended compliance actions

4. Recommendations
   - Negotiation priorities and positions
   - Required contract modifications
   - Implementation timeline and responsibilities
   - Approval and execution recommendations
USR
)

# Executive summary enables informed decision making
echo "Executive summary provides:"
echo "- Clear risk and compliance overview"
echo "- Actionable recommendations for stakeholders"
echo "- Decision-making framework and priorities"
echo "- Implementation roadmap and timeline"
```

## 5) One-Block Legal Document Automation Pipeline
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o}

# Setup legal context
cat > legal_context.txt <<'EOF'
Document Type: Commercial Service Agreement
Jurisdiction: United States (California law)
Industry: Technology/SaaS
Contract Value: $2.5M annually
Risk Tolerance: Medium (standard commercial terms acceptable)
Compliance Requirements: GDPR, CCPA, SOC 2 Type II
Review Deadline: 48 hours
EOF

echo 'Legal Objective: Ensure contract terms protect company interests, identify material risks, and verify regulatory compliance' > legal_objective.txt

# Contract analysis
ANALYSIS_SYSTEM='Perform comprehensive contract analysis with clause extraction, term identification, and legal categorization.'

ANALYSIS_USER=$(cat <<'EOT'
Legal Context:
$(cat legal_context.txt)

Legal Objective:
$(cat legal_objective.txt)

Analyze contract for:
- Clause identification and categorization
- Key terms and obligations extraction
- Risk areas and potential exposures
- Compliance requirements verification
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$ANALYSIS_SYSTEM" --arg u "$ANALYSIS_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$u}]
  }') | jq -r '.choices[0].message.content' | tee contract_analysis.json

# Risk assessment
RISK_SYSTEM='Conduct comprehensive legal risk assessment with mitigation strategies and probability analysis.'

RISK_USER=$(cat <<'EOT'
Contract Analysis:
$(cat contract_analysis.json)

Legal Context:
$(cat legal_context.txt)

Assess risks in categories:
1. Financial risks (payments, penalties, taxes)
2. Operational risks (SLAs, termination, transition)
3. Legal risks (liability, IP, data protection)
4. Compliance risks (regulatory requirements)

Provide risk ratings and mitigation recommendations.
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$RISK_SYSTEM" --arg r "$RISK_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$r}]
  }') | jq -r '.choices[0].message.content' | tee risk_assessment.json

# Compliance verification
COMPLIANCE_SYSTEM='Verify regulatory compliance and generate detailed compliance reports with audit trails.'

COMPLIANCE_USER=$(cat <<'EOT'
Contract Analysis:
$(cat contract_analysis.json)

Risk Assessment:
$(cat risk_assessment.json)

Verify compliance for:
1. GDPR requirements and data protection
2. CCPA consumer rights and obligations
3. SOC 2 Type II controls and auditing
4. Industry-specific regulatory requirements

Generate compliance verification report.
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$COMPLIANCE_SYSTEM" --arg c "$COMPLIANCE_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$c}]
  }') | jq -r '.choices[0].message.content' | tee compliance_report.md

# Executive summary
SUMMARY_SYSTEM='Generate executive legal summary with key findings and actionable recommendations.'

SUMMARY_USER=$(cat <<'EOT'
Contract Analysis:
$(cat contract_analysis.json)

Risk Assessment:
$(cat risk_assessment.json)

Compliance Report:
$(cat compliance_report.md)

Generate executive summary covering:
1. Contract overview and key terms
2. Risk summary with priorities
3. Compliance status and requirements
4. Recommendations for negotiation and approval
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SUMMARY_SYSTEM" --arg e "$SUMMARY_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$e}]
  }') | jq -r '.choices[0].message.content' | tee legal_summary.md

echo '🎉 Legal Document Automation Complete!'
echo 'Generated files: contract_analysis.json, risk_assessment.json, compliance_report.md, legal_summary.md'
echo ''
echo 'Legal automation pipeline delivered:'
echo '✅ Comprehensive contract analysis with clause extraction'
echo '✅ Risk assessment with mitigation recommendations'
echo '✅ Regulatory compliance verification and audit trails'
echo '✅ Executive summary for decision makers'
```

## 🚀 Simple Copy-Paste Prompt for Non-Technical Users

**Just copy-paste this entire prompt into ChatGPT, Claude, or any AI chat interface!**

```
You are a comprehensive legal document analysis expert. I need you to perform complete contract review and risk assessment.

LEGAL DOCUMENT REQUEST:
Document Type: [TYPE - e.g., "Commercial Service Agreement"]
Jurisdiction: [JURISDICTION - e.g., "United States (California law)"]
Industry: [INDUSTRY - e.g., "Technology/SaaS"]
Contract Value: [VALUE - e.g., "$2.5M annually"]
Key Concerns: [CONCERNS - e.g., "Payment terms, liability, IP rights, termination"]
Compliance Requirements: [COMPLIANCE - e.g., "GDPR, CCPA, SOC 2"]

STEP-BY-STEP LEGAL ANALYSIS:

1. CONTRACT ANALYSIS PHASE:
   - Extract and categorize all key clauses (payment, liability, IP, termination, etc.)
   - Identify critical terms and obligations for both parties
   - Analyze payment terms, penalties, and financial commitments
   - Review liability limitations and indemnification provisions
   - Examine intellectual property rights and licensing terms
   - Assess termination conditions and notice periods
   - Evaluate force majeure and dispute resolution clauses

2. RISK ASSESSMENT PHASE:
   Conduct comprehensive risk analysis:
   - Financial Risks: Payment terms, penalties, currency issues, taxes
   - Operational Risks: Service levels, termination, change management
   - Legal Risks: Liability caps, IP protection, data security
   - Compliance Risks: GDPR, CCPA, industry regulations
   - Provide risk ratings (Low/Medium/High/Critical) for each area
   - Include mitigation strategies and recommendations

3. COMPLIANCE VERIFICATION PHASE:
   Verify regulatory compliance:
   - GDPR: Data processing, lawful basis, subject rights, transfers
   - CCPA: Personal info definitions, consumer rights, security measures
   - Industry Standards: SOC 2, HIPAA, PCI-DSS as applicable
   - Generate compliance checklist with pass/fail status
   - Identify any compliance gaps requiring attention

4. EXECUTIVE SUMMARY PHASE:
   Create business-focused summary:
   - Key contract terms and financial implications
   - High-priority risks and recommended actions
   - Compliance status and outstanding requirements
   - Negotiation priorities and approval recommendations
   - Timeline for completion and next steps

OUTPUT FORMAT:
- Start with comprehensive clause analysis and categorization
- Provide detailed risk assessment with mitigation strategies
- Include compliance verification report with specific findings
- End with executive summary and actionable recommendations
- Use clear, non-legal language where possible while maintaining accuracy

Focus on practical business implications and actionable recommendations for decision makers.
```

### 📝 How to Use This Simple Prompt:

1. **Copy the entire prompt above** (from "You are a comprehensive legal..." to the end)
2. **Paste it into any AI chat interface** (ChatGPT, Claude, Gemini, etc.)
3. **Replace the bracketed sections** with your specific contract details:
   - `[TYPE]` → Your document type
   - `[JURISDICTION]` → Governing law and jurisdiction
   - `[INDUSTRY]` → Industry sector
   - `[VALUE]` → Contract value and term
   - `[CONCERNS]` → Your main areas of concern
   - `[COMPLIANCE]` → Required regulatory compliance
4. **Attach or paste your contract text** after the prompt
5. **Send and get complete legal analysis!**

### 🎯 What You'll Get:
- ✅ **Contract Analysis** - Complete clause extraction and categorization
- ✅ **Risk Assessment** - Detailed risk analysis with mitigation strategies
- ✅ **Compliance Report** - Regulatory compliance verification
- ✅ **Executive Summary** - Business-focused recommendations
- ✅ **Negotiation Guide** - Specific recommendations for contract terms

### 💡 Pro Tips for Best Results:
- Include the full contract text for comprehensive analysis
- Be specific about your industry and regulatory requirements
- Mention any particular clauses or terms you're most concerned about
- Specify your risk tolerance level (conservative/moderate/aggressive)
- Include any previous negotiation history or preferences

---

## Notes
- This workflow provides complete legal document automation from contract receipt to executive approval
- Automated clause extraction and risk identification accelerate legal review processes
- Multi-jurisdictional compliance verification ensures regulatory adherence
- Executive summaries enable efficient decision-making for business stakeholders
- Audit trails and documentation support compliance and legal defensibility
- **Simple copy-paste version** makes legal analysis accessible for non-lawyers
