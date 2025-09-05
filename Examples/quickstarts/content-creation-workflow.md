# Quickstart: Content Creation Workflow (Research → Outline → Draft → SEO Optimization)

Complete content generation pipeline from topic research to publication-ready content with SEO optimization. Produces:
- `content_research.json` (comprehensive topic research and analysis)
- `content_outline.md` (structured content outline with SEO keywords)
- `content_draft.md` (publication-ready draft with brand voice)
- `seo_analysis.json` (SEO performance predictions and optimization recommendations)

References: `Applications/market-surveys.md`, `Guides/retrieval-augmented-generation.md`, `JSON-Schemas/content-validation.json`.

## 0) Content Context Setup
```bash
cat > content_context.txt <<'EOF'
Topic: The Future of Electric Vehicles in Urban Transportation
Target Audience: Urban commuters aged 25-45, tech-savvy professionals
Content Platforms: Blog post, LinkedIn article, Twitter thread, Newsletter
Brand Voice: Professional yet approachable, data-driven, optimistic
SEO Priority: High (target keywords: electric vehicles, urban mobility, sustainable transport)
Content Length: 2000 words blog, 800 words LinkedIn, 280 chars Twitter
EOF

echo 'Business Objective: Position company as thought leader in urban EV solutions while driving organic traffic and lead generation' > content_objective.txt
```

PowerShell alternative:
```powershell
@'
Topic: The Future of Electric Vehicles in Urban Transportation
Target Audience: Urban commuters aged 25-45, tech-savvy professionals
Content Platforms: Blog post, LinkedIn article, Twitter thread, Newsletter
Brand Voice: Professional yet approachable, data-driven, optimistic
SEO Priority: High (target keywords: electric vehicles, urban mobility, sustainable transport)
Content Length: 2000 words blog, 800 words LinkedIn, 280 chars Twitter
'@ | Set-Content content_context.txt

@'Business Objective: Position company as thought leader in urban EV solutions while driving organic traffic and lead generation'@ | Set-Content content_objective.txt
```

## 1) Content Research & Analysis (RAG-Powered)
```
Comprehensive topic research with market insights and competitor analysis.
```

### Bash (OpenAI with Schema Validation)
```bash
SCHEMA=$(cat Prompting-Gold-Standard/JSON-Schemas/research-analysis.json)

SYSTEM='Generate comprehensive content research as valid JSON. Include market analysis, audience insights, competitor content, and SEO research with citation evidence.'

USER=$(cat <<'USR'
Content Context:
$(cat content_context.txt)

Business Objective:
$(cat content_objective.txt)

Research Requirements:
- Market trends and statistics for electric vehicles
- Target audience pain points and preferences
- Competitor content analysis and gaps
- SEO keyword research and search intent
- Social media trends and engagement patterns
- Industry expert opinions and thought leadership
- Data sources and citation requirements
USR
)

# Research-driven content creation ensures accuracy and authority
echo "Research phase integrates:"
echo "- Market data and industry statistics"
echo "- Audience behavior and preferences"
echo "- Competitor content strategies"
echo "- SEO keyword opportunities"
echo "- Social media engagement patterns"
```

## 2) Content Outline Generation (SEO-Optimized)
```
Create structured content outlines with SEO keywords and engagement hooks.
```

### Bash (OpenAI)
```bash
OUTLINE_SYSTEM='Generate SEO-optimized content outline with compelling hooks, keyword integration, and engagement elements for multiple platforms.'

OUTLINE_USER=$(cat <<'USR'
Content Research:
$(cat content_research.json)

Content Context:
$(cat content_context.txt)

Create Content Outlines for:
1. Blog Post Outline (2000 words)
   - SEO-optimized title and headings
   - Keyword-rich introduction with hook
   - Data-driven body sections
   - Call-to-action conclusion
   - Internal/external linking strategy

2. LinkedIn Article Outline (800 words)
   - Professional headline and lede
   - Industry insights and thought leadership
   - Personal anecdotes and credibility
   - Call-to-action for engagement

3. Twitter Thread Outline (280 chars × 10 tweets)
   - Hook tweet with question/statistic
   - Value-driven thread structure
   - Engagement prompts and hashtags
   - Call-to-action and lead magnet

4. Newsletter Outline (500 words)
   - Compelling subject line
   - Personalized greeting and context
   - Key insights and takeaways
   - Exclusive content preview
USR
)

# Multi-platform content strategy maximizes reach and engagement
echo "Multi-platform outlines ensure:"
echo "- Consistent messaging across channels"
echo "- Platform-specific optimization"
echo "- SEO keyword integration"
echo "- Audience engagement hooks"
```

## 3) Content Draft Generation (Brand Voice Adaptation)
```
Create publication-ready drafts with consistent brand voice and tone.
```

### Bash (OpenAI)
```bash
DRAFT_SYSTEM='Generate publication-ready content drafts with consistent brand voice, compelling narratives, and platform-specific formatting.'

DRAFT_USER=$(cat <<'USR'
Content Outline:
$(cat content_outline.md)

Content Research:
$(cat content_research.json)

Content Context:
$(cat content_context.txt)

Generate Content Drafts:

1. Blog Post Draft (2000 words)
   - Compelling headline and subheadings
   - Data-driven narrative with statistics
   - Industry expert quotes and insights
   - Visual content suggestions
   - SEO-optimized meta description

2. LinkedIn Article Draft (800 words)
   - Professional yet approachable tone
   - Industry thought leadership positioning
   - Call-to-action for professional engagement
   - Hashtags and formatting for LinkedIn

3. Twitter Thread Draft (10 tweets × 280 chars)
   - Hook with compelling statistic or question
   - Value-packed thread with data points
   - Engagement questions and polls
   - Lead magnet and call-to-action

4. Newsletter Draft (500 words)
   - Personalized greeting and context
   - Key insights from research
   - Exclusive content or offer
   - Professional sign-off and contact info
USR
)

# Brand voice consistency ensures professional credibility
echo "Brand voice adaptation includes:"
echo "- Consistent tone and messaging"
echo "- Platform-specific formatting"
echo "- Audience-appropriate language"
echo "- Company values and positioning"
```

## 4) SEO Analysis & Optimization (Performance Prediction)
```
Analyze SEO performance and provide optimization recommendations.
```

### Bash (OpenAI)
```bash
SEO_SYSTEM='Analyze content SEO performance with keyword optimization, readability scores, and engagement predictions.'

SEO_USER=$(cat <<'USR'
Content Drafts:
$(cat content_draft.md)

Content Research:
$(cat content_research.json)

SEO Analysis Requirements:
1. Keyword Performance Analysis
   - Primary keyword density and placement
   - Secondary keyword integration
   - Long-tail keyword opportunities
   - Keyword stuffing risks

2. Content Quality Metrics
   - Readability scores (Flesch-Kincaid)
   - Engagement potential prediction
   - Shareability and virality assessment
   - Mobile optimization check

3. SEO Optimization Recommendations
   - Title tag and meta description optimization
   - Heading structure improvements
   - Internal/external linking suggestions
   - Image alt-text and schema markup

4. Performance Predictions
   - Estimated organic traffic potential
   - Social media engagement forecast
   - Conversion rate predictions
   - Competitive ranking analysis
USR
)

# Data-driven SEO optimization maximizes organic reach
echo "SEO analysis provides:"
echo "- Performance predictions and benchmarks"
echo "- Optimization recommendations"
echo "- Competitive analysis insights"
echo "- Content improvement suggestions"
```

## 5) One-Block Content Creation Pipeline
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o}

# Setup content context
cat > content_context.txt <<'EOF'
Topic: The Future of Electric Vehicles in Urban Transportation
Target Audience: Urban commuters aged 25-45, tech-savvy professionals
Content Platforms: Blog post, LinkedIn article, Twitter thread, Newsletter
Brand Voice: Professional yet approachable, data-driven, optimistic
SEO Priority: High (target keywords: electric vehicles, urban mobility, sustainable transport)
Content Length: 2000 words blog, 800 words LinkedIn, 280 chars Twitter
EOF

echo 'Business Objective: Position company as thought leader in urban EV solutions while driving organic traffic and lead generation' > content_objective.txt

# Generate content research
RESEARCH_SYSTEM='Generate comprehensive content research with market insights, audience analysis, and competitor research.'

RESEARCH_USER=$(cat <<'EOT'
Content Context:
$(cat content_context.txt)

Business Objective:
$(cat content_objective.txt)

Research comprehensive data on:
- EV market trends and adoption statistics
- Urban mobility challenges and solutions
- Target audience preferences and behaviors
- Competitor content strategies and gaps
- SEO keyword opportunities and search volume
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$RESEARCH_SYSTEM" --arg u "$RESEARCH_USER" '{
    model:$m, temperature:0.2,
    messages:[{role:"system",content:$s},{role:"user",content:$u}]
  }') | jq -r '.choices[0].message.content' | tee content_research.json

# Generate content outlines
OUTLINE_SYSTEM='Create SEO-optimized content outlines for multiple platforms with keyword integration and engagement hooks.'

OUTLINE_USER=$(cat <<'EOT'
Content Research:
$(cat content_research.json)

Content Context:
$(cat content_context.txt)

Generate outlines for:
1. SEO-optimized blog post structure
2. Professional LinkedIn article framework
3. Engaging Twitter thread sequence
4. Newsletter content flow with CTAs
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$OUTLINE_SYSTEM" --arg p "$OUTLINE_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$p}]
  }') | jq -r '.choices[0].message.content' | tee content_outline.md

# Generate content drafts
DRAFT_SYSTEM='Create publication-ready content with consistent brand voice and platform-specific formatting.'

DRAFT_USER=$(cat <<'EOT'
Content Outline:
$(cat content_outline.md)

Content Research:
$(cat content_research.json)

Generate drafts for all platforms with:
- Compelling headlines and hooks
- Data-driven narratives
- Brand voice consistency
- Platform-specific formatting
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$DRAFT_SYSTEM" --arg d "$DRAFT_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$d}]
  }') | jq -r '.choices[0].message.content' | tee content_draft.md

# Generate SEO analysis
SEO_SYSTEM='Analyze content SEO performance with optimization recommendations and performance predictions.'

SEO_USER=$(cat <<'EOT'
Content Drafts:
$(cat content_draft.md)

Content Research:
$(cat content_research.json)

Provide SEO analysis covering:
1. Keyword performance and optimization
2. Readability and engagement metrics
3. SEO recommendations and improvements
4. Performance predictions and benchmarks
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SEO_SYSTEM" --arg e "$SEO_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$e}]
  }') | jq -r '.choices[0].message.content' | tee seo_analysis.json

echo '🎉 Content Creation Workflow Complete!'
echo 'Generated files: content_research.json, content_outline.md, content_draft.md, seo_analysis.json'
echo ''
echo 'Content creation pipeline delivered:'
echo '✅ Comprehensive topic research with market insights'
echo '✅ Multi-platform content outlines with SEO optimization'
echo '✅ Publication-ready drafts with brand voice consistency'
echo '✅ SEO performance analysis and optimization recommendations'
```

## 🚀 Simple Copy-Paste Prompt for Non-Technical Users

**Just copy-paste this entire prompt into ChatGPT, Claude, or any AI chat interface!**

```
You are a comprehensive content creation expert. I need you to create complete content from research to publication-ready drafts.

CONTENT REQUEST:
Topic: [YOUR TOPIC HERE - e.g., "The Future of AI in Healthcare"]
Target Audience: [YOUR AUDIENCE - e.g., "Healthcare professionals aged 30-50"]
Content Platforms: [PLATFORMS - e.g., "Blog post, LinkedIn article, Twitter thread"]
Brand Voice: [VOICE - e.g., "Professional, data-driven, authoritative"]
SEO Keywords: [KEYWORDS - e.g., "AI healthcare, medical technology, digital health"]
Word Count: [LENGTH - e.g., "2000 words blog, 800 words LinkedIn"]

STEP-BY-STEP PROCESS:

1. CONTENT RESEARCH PHASE:
   - Research current market trends and statistics
   - Analyze target audience pain points and preferences
   - Study competitor content strategies and identify gaps
   - Perform SEO keyword research and search intent analysis
   - Identify social media trends and engagement patterns
   - Gather industry expert opinions and thought leadership insights

2. CONTENT OUTLINE PHASE:
   Create SEO-optimized outlines for ALL requested platforms:
   - Blog Post: SEO title, keyword-rich headings, data-driven sections, CTA conclusion
   - LinkedIn: Professional headline, thought leadership structure, engagement hooks
   - Twitter Thread: Hook tweet, value-driven sequence, engagement prompts
   - Newsletter: Subject line, personalized greeting, key insights, exclusive content

3. CONTENT DRAFT PHASE:
   Generate publication-ready drafts with:
   - Compelling headlines and attention-grabbing hooks
   - Data-driven narratives supported by statistics
   - Industry expert quotes and credible sources
   - Platform-specific formatting and tone adaptation
   - Brand voice consistency throughout

4. SEO ANALYSIS PHASE:
   Analyze and provide:
   - Keyword density and optimal placement recommendations
   - Readability scores and improvement suggestions
   - SEO optimization recommendations (title tags, meta descriptions, headings)
   - Performance predictions (organic traffic potential, engagement forecast)
   - Content improvement suggestions for better rankings

OUTPUT FORMAT:
- Start with comprehensive research summary
- Provide detailed outlines for each platform
- Deliver complete drafts ready for publication
- End with SEO analysis and optimization recommendations
- Include specific metrics and performance predictions

Make this content authoritative, data-driven, and optimized for both human readers and search engines.
```

### 📝 How to Use This Simple Prompt:

1. **Copy the entire prompt above** (from "You are a comprehensive..." to the end)
2. **Paste it into any AI chat interface** (ChatGPT, Claude, Gemini, etc.)
3. **Replace the bracketed sections** with your specific requirements:
   - `[YOUR TOPIC HERE]` → Your actual topic
   - `[YOUR AUDIENCE]` → Your target audience
   - `[PLATFORMS]` → Desired platforms
   - `[VOICE]` → Your brand voice
   - `[KEYWORDS]` → Target SEO keywords
   - `[LENGTH]` → Desired word counts
4. **Send the prompt** and get complete content creation workflow results!

### 🎯 What You'll Get:
- ✅ **Research Report** - Market insights and audience analysis
- ✅ **Content Outlines** - SEO-optimized structures for each platform
- ✅ **Publication-Ready Drafts** - Complete content ready to publish
- ✅ **SEO Analysis** - Performance predictions and optimization tips
- ✅ **Multi-Platform Content** - Adapted for different social channels

### 💡 Pro Tips for Best Results:
- Be specific about your target audience demographics and interests
- Include 3-5 primary SEO keywords you want to rank for
- Specify the content length that works for your publishing schedule
- Mention any specific data sources or industry reports you want included
- Add any brand-specific terminology or messaging requirements

---

## Notes
- This workflow creates a complete content marketing pipeline from research to publication
- Multi-platform optimization ensures maximum reach and engagement across channels
- SEO integration maximizes organic traffic and lead generation potential
- Brand voice consistency maintains professional credibility and recognition
- Research-driven approach ensures content accuracy and thought leadership positioning
- **Simple copy-paste version** makes it accessible for non-technical users
