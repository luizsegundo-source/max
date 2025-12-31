# 🏥 MAX - Medical Assistant eXpert

Sistema de gestão inteligente para o consultório do **Dr. Luiz Segundo**.  
Especialista em Cirurgia de Parede Abdominal (Hérnias e Diástase) | Vitória/ES

---

## 📋 Visão Geral

MAX é um ecossistema completo de gestão médica que inclui:

- 🤖 **Assistente IA** para WhatsApp (atendimento 24h)
- 📅 **Agendamento automático** com Google Calendar
- 📄 **Processamento de documentos** com Claude Vision
- 💰 **Sistema financeiro** integrado
- ✍️ **Assinatura digital** com D4Sign
- 📊 **Dashboard** de gestão

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                        PACIENTES                            │
│                     (WhatsApp/App)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      Z-API (WhatsApp)                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    n8n Cloud (Automações)                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │   MAX   │ │ Agenda  │ │  Docs   │ │Financ.  │          │
│  │Assistant│ │ Manager │ │ Manager │ │ Manager │          │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘          │
└───────┼──────────┼──────────┼──────────┼────────────────────┘
        │          │          │          │
        ▼          ▼          ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│                  Supabase (PostgreSQL)                      │
│              Schema: clinica | LGPD Compliant               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura do Repositório

```
max/
├── README.md
├── .supabase/                    # Config Supabase CLI
├── docs/
│   ├── arquitetura.md
│   ├── regras-negocio.md
│   └── api-endpoints.md
├── supabase/
│   ├── schema/
│   │   ├── 01-tipos-enums.sql
│   │   ├── 02-tabelas-core.sql
│   │   ├── 03-tabelas-financeiro.sql
│   │   ├── 04-views.sql
│   │   ├── 05-functions.sql
│   │   └── 06-triggers-rls.sql
│   └── migrations/
├── n8n/
│   └── workflows/                # Exports JSON dos workflows
└── scripts/
    └── backup.sh
```

---

## 🚀 Stack Tecnológico

| Componente | Tecnologia |
|------------|------------|
| Automação | n8n Cloud |
| Banco de Dados | Supabase (PostgreSQL) |
| WhatsApp | Z-API |
| Calendário | Google Calendar |
| IA Conversacional | Claude (Anthropic) |
| IA Documentos | Claude Vision |
| Assinatura Digital | D4Sign |
| Frontend (futuro) | Next.js 14 |

---

## 📍 Locais de Atendimento

| Local | Dia | Horário | Convênios |
|-------|-----|---------|-----------|
| **Global Tower** (Vitória) | Quarta | 08:00-12:00 | Unimed, Nova Saúde, Particular |
| **GRAMEG** (Vila Velha) | Quinta | 08:00-12:00 | Todos |

---

## 🔧 Workflows n8n Ativos (22)

### Core
- `MAX-Assistente` - IA conversacional principal
- `MAX-Verificar-Disponibilidade` - Consulta agenda
- `MAX-Criar-Agendamento` - Reserva horários
- `MAX-Confirmacao-24h` - Lembrete automático

### Financeiro
- `MAX-Financeiro-Manager` - CRUD financeiro
- `MAX-Financeiro-Diario` - Resumo 6h (WhatsApp)

### Documentos
- `MAX-Documentos-Manager` - Upload e análise
- `MAX-D4Sign-Completo` - Assinatura digital
- `MAX-Gerar-Guias-Medicas` - PDFs automáticos

### Cirurgia
- `MAX-Cirurgia-Manager` - Controle cirúrgico
- `MAX-OTP-BirdID-Diario` - Assinatura certificada

---

## 💰 Sistema Financeiro

### Calendário de Pagamentos
| Dia | Descrição | Valor |
|-----|-----------|-------|
| 1 | Aluguéis (Global + GRAMEG) | R$ 1.500 |
| 10 | Contabilidade Sante | R$ 250 |
| 20 | Dany (Fixo + 5% particular) | R$ 4.000+ |
| 20 | Contabilidade S&C + Impostos | Variável |

### Ciclos de Faturamento
- **Nova Saúde**: Execução → Extrato (último útil) → NF → Pagamento
- **Hospitais**: Execução → Faturamento (N+1) → NF (N+2) → Pagamento

---

## 📊 Métricas

- **1.469 pacientes** cadastrados
- **3.000+ eventos** históricos importados
- **22 workflows** ativos
- **100% LGPD** compliant

---

## 🔐 Segurança

- ✅ Row Level Security (RLS)
- ✅ Audit logs automáticos
- ✅ Soft delete (LGPD)
- ✅ Criptografia em repouso
- ✅ Consentimento registrado

---

## 📝 Licença

Projeto privado - Dr. Luiz Segundo © 2024-2025

---

## 👥 Equipe

- **Dr. Luiz Segundo** - Médico / Product Owner
- **Dany** - Assistente Administrativa  
- **MAX** - Assistente Virtual IA
