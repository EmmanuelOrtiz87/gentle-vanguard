# Doc-Gentle - Document Intelligence Platform

> **Archived specification — not a publishable application.** Retained as product research only. The
> supported document-processing capability lives in the root TypeScript stack and its
> `document-processor` skill.

## 🎯 Product Vision

Doc-Gentle es una plataforma de inteligencia documental que permite a usuarios subir documentos
(PDF, Word, imágenes, URLs) y obtener análisis impulsados por IA: resúmenes, insights, traducciones,
y Q&A interactivo.

## 📊 Market Analysis

### Target Market

- **Primary**: Knowledge workers, researchers, students
- **Secondary**: Legal firms, healthcare, financial services
- **TAM**: $15B document management software market (2024)
- **SAM**: $2B AI document processing segment

### Competitors

| Product   | Price  | Features   | Weakness         |
| --------- | ------ | ---------- | ---------------- |
| ChatPDF   | $10/mo | Basic Q&A  | Limited formats  |
| Claude.ai | $20/mo | Analysis   | No native OCR    |
| Notion AI | $10/mo | Summaries  | Locked to Notion |
| DocuSign  | $25/mo | Signatures | No analysis      |

### Competitive Advantages

- ✅ Multi-format: PDF, DOCX, JPG, PNG, URLs
- ✅ OCR nativo: Tesseract.js integrado
- ✅ Multi-language: 50+ idiomas
- ✅ Privacy-first: Procesamiento local
- ✅ API disponible: Para integraciones

## 💰 Business Model

### Freemium Tiers

```
Free ($0)
├── 5 documentos/mes
├── 10 MB por archivo
├── Resúmenes básicos
├── Soporte comunidad
└── Watermark en export

Pro ($15/mes)
├── Documentos ilimitados
├── 50 MB por archivo
├── Análisis avanzados
├── Export sin watermark
├── API access
└── Soporte prioritario

Enterprise ($99/mes)
├── Todo de Pro
├── SSO/SAML
├── On-premise option
├── Custom models
├── SLA 99.9%
└── Soporte 24/7
```

### Revenue Projections

| Month | Free Users | Pro Users | Enterprise | Monthly Revenue |
| ----- | ---------- | --------- | ---------- | --------------- |
| 1     | 500        | 10        | 0          | $150            |
| 6     | 5,000      | 150       | 2          | $2,448          |
| 12    | 20,000     | 800       | 10         | $13,890         |

## 🏗️ Technical Architecture

### Frontend

- **Framework**: React 18 + TypeScript
- **Build**: Vite
- **UI**: Tailwind CSS + Headless UI
- **State**: Zustand
- **Drag & Drop**: react-dropzone
- **Animations**: Framer Motion

### Document Processing

| Format | Library      | Status       |
| ------ | ------------ | ------------ |
| PDF    | pdf-parse    | ✅ Ready     |
| DOCX   | mammoth.js   | ✅ Ready     |
| Images | Tesseract.js | ✅ OCR ready |
| URLs   | Cheerio      | ✅ Ready     |

### AI Pipeline

```
Upload → Preprocess → OCR → Chunk → Embed → Store → Query → Generate
```

### Infrastructure

- **Hosting**: Vercel (frontend) + Railway (backend)
- **Storage**: Supabase (documents) + Pinecone (embeddings)
- **Queue**: BullMQ for async processing
- **Monitoring**: Gentle-Vanguard dashboard

## 📋 Feature Roadmap

### Phase 1 - MVP (Month 1)

- [ ] Upload PDF + DOCX
- [ ] Basic summaries
- [ ] Chat interface
- [ ] Export to PDF

### Phase 2 - Core (Months 2-3)

- [ ] Image OCR
- [ ] URL scraping
- [ ] Multi-document chat
- [ ] API endpoints

### Phase 3 - Scale (Months 4-6)

- [ ] 50+ languages
- [ ] Custom fine-tuning
- [ ] Collaborative workspaces
- [ ] Mobile app

### Phase 4 - Enterprise (Months 7-12)

- [ ] On-premise deployment
- [ ] Custom models
- [ ] Advanced analytics
- [ ] Enterprise SSO

## 🎨 Brand Assets

### Logo

- **Primary**: gradient cyan-purple document icon
- **Icon**: 📄 with ✨ overlay
- **Colors**: Same as Gentle-Vanguard

### Taglines

1. "Documents that understand you"
2. "Chat with your documents"
3. "AI-powered document intelligence"
4. "Don't just read documents, understand them"

### Landing Page Copy

```
Hero: "Transform your documents into knowledge"

Subheadline: "Upload PDFs, Word docs, images, or URLs.
Get instant summaries, insights, and answers powered by AI."

CTA: "Start free →"
```

## 📈 Marketing Strategy

### Launch Plan

1. **Week 1**: Beta signup (100 users)
2. **Week 2**: Product Hunt launch
3. **Week 3**: Twitter thread + demo video
4. **Week 4**: Reddit AMA + Hacker News

### Content Calendar

- **Monday**: Feature highlight
- **Wednesday**: User story/case study
- **Friday**: Quick tip/tutorial

### Partnerships

- Educational institutions
- Legal software providers
- Research organizations
- Content management platforms

## 🔒 Legal & Compliance

### Privacy

- GDPR compliant
- SOC 2 Type II (planned)
- HIPAA compliant version available

### Terms

- Standard SaaS terms
- Enterprise custom contracts
- 30-day money-back guarantee

## 📊 Success Metrics

### Monthly

- User growth: 20% MoM
- Conversion rate: 3% free→paid
- Churn: <5%
- NPS: >50

### Quarterly

- ARR (Annual Recurring Revenue)
- CAC (Customer Acquisition Cost)
- LTV (Lifetime Value)
- LTV/CAC ratio: >3x

---

**Last Updated**: 2026-08-10 **Version**: 1.0.0 **Owner**: Gentle-Vanguard Team
