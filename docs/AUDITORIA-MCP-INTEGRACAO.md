# Auditoria: Integração MCP com Supabase e Claudia

**Projeto:** MAX - Medical Assistant eXpert
**Data:** 2026-01-01
**Auditor:** Claude Code
**Branch:** `claude/audit-mcp-integration-rgtHf`

---

## Sumário Executivo

### Descoberta Principal

**A integração MCP (Model Context Protocol) e Claudia NÃO existe no codebase atual.** O branch foi criado para planejar/auditar esta integração, mas a implementação ainda não foi realizada.

### Status Atual do Sistema

| Componente | Status | Observação |
|------------|--------|------------|
| Supabase | ✅ Configurado | PostgreSQL com schema `clinica` |
| n8n Cloud | ✅ Em produção | 22 workflows ativos |
| Z-API (WhatsApp) | ✅ Integrado | Via n8n |
| Claude (IA) | ⚠️ Parcial | Usado via n8n, não via MCP |
| MCP | ❌ Não implementado | Nenhum código encontrado |
| Claudia | ❌ Não encontrado | Nenhuma referência no código |

---

## 1. Arquitetura Atual

```
┌─────────────────────────────────────────────────────────────┐
│                      PACIENTES                               │
│                   (WhatsApp/Telefone)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Z-API (WhatsApp Gateway)                  │
│                    [Webhook → n8n]                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    n8n Cloud (Automações)                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │MAX-Assistente│ │MAX-Agenda   │ │MAX-Financeiro│          │
│  │  (Claude AI) │ │  Manager    │ │   Manager    │          │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘           │
│         │               │               │                   │
│         ▼               ▼               ▼                   │
│  ┌────────────────────────────────────────┐                │
│  │         Anthropic API (Claude)          │                │
│  └────────────────────────────────────────┘                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  Supabase (PostgreSQL 15)                    │
│                  Schema: clinica                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │pacientes │ │agendamen.│ │cirurgias │ │financeiro│       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Análise da Integração Supabase

### 2.1 Configuração (`.supabase/config.toml`)

| Parâmetro | Valor | Avaliação |
|-----------|-------|-----------|
| Project ID | `txhxpasuyxdhlkyqmmii` | ✅ Configurado |
| PostgreSQL | v15 | ✅ Versão atual |
| API Port | 54321 | ✅ Padrão |
| Schemas | `public`, `clinica` | ✅ Bem estruturado |
| JWT Expiry | 3600s (1h) | ⚠️ Curto para sessões longas |
| File Size Limit | 50MiB | ✅ Adequado |
| Email Confirmations | Desabilitado | ⚠️ Risco de segurança |
| Anonymous Sign-ins | Desabilitado | ✅ Correto |

### 2.2 Schema do Banco de Dados

**Tabelas principais no schema `clinica`:**

| Tabela | Propósito | RLS |
|--------|-----------|-----|
| `pacientes` | Cadastro de pacientes | ✅ |
| `agendamentos` | Agenda de consultas | ✅ |
| `cirurgias` | Procedimentos cirúrgicos | ✅ |
| `convenios` | Planos de saúde | ✅ |
| `hospitais` | Locais de atendimento | ✅ |
| `usuarios` | Equipe (3 usuários) | ✅ |
| `contas_pagar` | Financeiro - saídas | ✅ |
| `contas_receber` | Financeiro - entradas | ✅ |
| `documentos` | Anexos e exames | ✅ |
| `mensagens_templates` | 17 templates WhatsApp | ✅ |

### 2.3 Funções PostgreSQL

```sql
-- Funções encontradas:
clinica.buscar_valor_consulta(convenio, local)     -- Retorna valor da consulta
clinica.convenio_atende_local(convenio, local)     -- Verifica cobertura
clinica.locais_por_convenio(convenio)              -- Lista locais disponíveis
clinica.dias_desde_consulta(paciente_id)           -- Calcula dias desde última consulta
clinica.e_retorno(paciente_id)                     -- Verifica se é retorno (<30 dias)
clinica.calcular_comissao_dany(mes, ano)           -- Calcula 5% sobre particulares
clinica.gerar_contas_mes(mes, ano)                 -- Gera contas fixas mensais
clinica.verificar_alertas_financeiros()            -- Retorna alertas pendentes
clinica.atualizacao_diaria_completa()              -- Job diário de manutenção
```

### 2.4 Problemas Identificados no Supabase

| # | Severidade | Problema | Localização |
|---|------------|----------|-------------|
| 1 | 🟠 Média | Política RLS muito permissiva: `FOR ALL USING (true)` | `03-tabelas-financeiro.sql:601-610` |
| 2 | 🟠 Média | Confirmação de email desabilitada | `config.toml:36` |
| 3 | 🟡 Baixa | Valor padrão hardcoded `R$110` para convênios não cadastrados | Migration linha 537 |
| 4 | 🟡 Baixa | Telefones da equipe expostos no seed.sql | `seed.sql:13-15` |
| 5 | 🟡 Baixa | Schema incompleto - faltam arquivos SQL referenciados no README | Estrutura |

---

## 3. Status da Integração MCP

### 3.1 Resultado da Busca

```bash
# Busca por "mcp" no código
grep -ri "mcp" . --include="*.{js,ts,json,sql,md,toml}"
# Resultado: 0 matches

# Busca por "claudia" no código
grep -ri "claudia" . --include="*.{js,ts,json,sql,md,toml}"
# Resultado: 0 matches
```

### 3.2 Conclusão

**NÃO existe integração MCP no projeto.** O sistema usa Claude via:
- API Anthropic direta através do n8n
- Chamadas HTTP nos workflows de automação

---

## 4. Análise de Segurança

### 4.1 Pontos Positivos

| Item | Implementação |
|------|---------------|
| Row Level Security (RLS) | ✅ Habilitado em todas as tabelas |
| Soft Delete (LGPD) | ✅ Campo `deletado_em` em vez de DELETE |
| Audit Logs | ✅ Campos `criado_em`, `atualizado_em` |
| UUIDs | ✅ Uso de UUIDs em vez de IDs sequenciais |
| Triggers de Timestamp | ✅ Atualização automática |

### 4.2 Vulnerabilidades e Riscos

| # | Severidade | Risco | Descrição | Recomendação |
|---|------------|-------|-----------|--------------|
| 1 | 🔴 Alta | Políticas RLS permissivas | `USING (true)` permite acesso total | Implementar políticas baseadas em `auth.uid()` |
| 2 | 🔴 Alta | Credenciais ausentes | Sem `.env` no repo - onde estão armazenadas? | Documentar gestão de segredos |
| 3 | 🟠 Média | Dados PII no seed | Telefones e emails reais expostos | Usar dados fictícios no seed |
| 4 | 🟠 Média | Sem MFA | Não há menção a autenticação multifator | Habilitar MFA no Supabase |
| 5 | 🟡 Baixa | JWT curto (1h) | Pode causar problemas de UX | Considerar refresh tokens |

### 4.3 Conformidade LGPD

| Requisito | Status | Observação |
|-----------|--------|------------|
| Soft delete | ✅ | Implementado via `deletado_em` |
| Consentimento | ✅ | Campo `consentimento_registrado` |
| Portabilidade | ⚠️ | Não há função de exportação |
| Anonimização | ⚠️ | Não implementado |
| Logs de acesso | ✅ | Via audit logs do Supabase |

---

## 5. Recomendações para Integração MCP

### 5.1 O que é MCP?

MCP (Model Context Protocol) é um protocolo da Anthropic para conectar LLMs a fontes de dados e ferramentas. Permitiria que Claude acesse diretamente o Supabase sem passar pelo n8n.

### 5.2 Arquitetura Proposta com MCP

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude (via MCP)                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   MCP Server                          │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐             │   │
│  │  │Supabase  │ │Google    │ │WhatsApp  │             │   │
│  │  │Connector │ │Calendar  │ │Connector │             │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘             │   │
│  └───────┼────────────┼────────────┼────────────────────┘   │
└──────────┼────────────┼────────────┼────────────────────────┘
           │            │            │
           ▼            ▼            ▼
      [Supabase]  [Google Cal]  [Z-API]
```

### 5.3 Passos para Implementação

#### Fase 1: Preparação (Prioridade Alta)

1. **Criar servidor MCP em TypeScript/Node.js**
   ```typescript
   // mcp-server/src/index.ts
   import { Server } from "@modelcontextprotocol/sdk/server";
   import { createClient } from "@supabase/supabase-js";
   ```

2. **Configurar variáveis de ambiente**
   ```env
   SUPABASE_URL=https://txhxpasuyxdhlkyqmmii.supabase.co
   SUPABASE_SERVICE_KEY=<service_role_key>
   CLAUDE_API_KEY=<anthropic_api_key>
   ```

3. **Definir ferramentas MCP**
   - `buscar_paciente` - Busca por nome/telefone
   - `criar_agendamento` - Agendar consulta
   - `listar_horarios` - Verificar disponibilidade
   - `criar_conta_receber` - Registrar faturamento

#### Fase 2: Implementação (Prioridade Média)

4. **Implementar conectores**
   ```typescript
   // Exemplo de ferramenta MCP
   server.tool("buscar_paciente", {
     description: "Busca paciente por telefone",
     parameters: {
       telefone: { type: "string" }
     },
     handler: async ({ telefone }) => {
       const { data } = await supabase
         .from("pacientes")
         .select("*")
         .eq("telefone", telefone)
         .single();
       return data;
     }
   });
   ```

5. **Migrar workflows do n8n gradualmente**
   - Começar com workflows de leitura (baixo risco)
   - Depois migrar escrita (agendamentos, etc.)

#### Fase 3: Produção (Prioridade Baixa)

6. **Testes e homologação**
7. **Deploy em ambiente de produção**
8. **Monitoramento e logs**

### 5.4 Sobre "Claudia"

Não encontrei referências a "Claudia" no código. Possíveis interpretações:

1. **Nome interno para o assistente MAX** - O bot se chama "MAX", não "Claudia"
2. **Projeto futuro** - Um novo componente ainda não implementado
3. **Erro de nomenclatura** - Confusão com "Claude"

**Recomendação:** Esclarecer com o stakeholder o que "Claudia" significa no contexto do projeto.

---

## 6. Arquivos Faltantes

Arquivos referenciados no README que não existem:

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `docs/arquitetura.md` | ❌ Faltando | Documentação |
| `docs/api-endpoints.md` | ❌ Faltando | Documentação |
| `supabase/schema/01-tipos-enums.sql` | ❌ Faltando | Schema incompleto |
| `supabase/schema/02-tabelas-core.sql` | ❌ Faltando | Schema incompleto |
| `supabase/schema/04-views.sql` | ❌ Faltando | Schema incompleto |
| `supabase/schema/05-functions.sql` | ❌ Faltando | Schema incompleto |
| `supabase/schema/06-triggers-rls.sql` | ❌ Faltando | Schema incompleto |
| `n8n/workflows/*.json` | ❌ Faltando | Backup workflows |
| `scripts/backup.sh` | ❌ Faltando | Automação |

---

## 7. Métricas do Projeto

| Métrica | Valor |
|---------|-------|
| Pacientes cadastrados | 1.469 |
| Eventos históricos | 3.000+ |
| Workflows n8n ativos | 22 |
| Tabelas no schema clinica | ~15 |
| Templates de mensagem | 17 |
| Usuários do sistema | 3 |

---

## 8. Conclusões

### 8.1 Resumo

1. **O projeto NÃO possui integração MCP** - apenas usa Claude via API no n8n
2. **"Claudia" não existe no código** - precisa de esclarecimento
3. **Supabase está bem configurado** com algumas melhorias de segurança necessárias
4. **Documentação incompleta** - vários arquivos referenciados estão faltando

### 8.2 Prioridades de Ação

| Prioridade | Ação | Esforço |
|------------|------|---------|
| 🔴 Alta | Corrigir políticas RLS permissivas | 2-4h |
| 🔴 Alta | Documentar gestão de credenciais | 1-2h |
| 🟠 Média | Criar arquivos SQL faltantes | 4-8h |
| 🟠 Média | Remover dados PII do seed | 1h |
| 🟡 Baixa | Implementar MCP (se desejado) | 20-40h |
| 🟡 Baixa | Criar documentação completa | 8-16h |

### 8.3 Próximos Passos

1. **Imediato:** Esclarecer o que é "Claudia" e se MCP é realmente necessário
2. **Curto prazo:** Corrigir vulnerabilidades de segurança identificadas
3. **Médio prazo:** Completar documentação e schemas faltantes
4. **Longo prazo:** Avaliar benefícios de MCP vs arquitetura atual com n8n

---

## Anexos

### A. Estrutura Atual de Arquivos

```
max/
├── README.md                                          ✅
├── package.json                                       ✅ (básico)
├── index.html                                         ✅ (frontend demo)
├── vercel.json                                        ✅
├── max-repo-update.zip                                ✅
├── .supabase/
│   ├── config.toml                                    ✅
│   ├── seed.sql                                       ✅
│   └── migrations/
│       ├── 20241228000001_protocolo_agendamento_v2.sql ✅
│       ├── supabase/schema/
│       │   └── 03-tabelas-financeiro.sql              ✅
│       └── docs/
│           └── regras-negocio.md                      ✅
├── docs/                                              ❌ (vazio)
├── supabase/schema/                                   ❌ (faltando)
├── n8n/workflows/                                     ❌ (faltando)
└── scripts/                                           ❌ (faltando)
```

### B. Configurações de Segurança Recomendadas

```sql
-- Substituir política atual:
-- CREATE POLICY "Service role full access" ON clinica.contas_pagar FOR ALL USING (true);

-- Por políticas granulares:
CREATE POLICY "Apenas equipe pode ver contas" ON clinica.contas_pagar
  FOR SELECT USING (
    auth.uid() IN (SELECT id FROM clinica.usuarios WHERE ativo = true)
  );

CREATE POLICY "Apenas admin pode modificar contas" ON clinica.contas_pagar
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM clinica.usuarios
      WHERE id = auth.uid() AND perfil = 'admin'
    )
  );
```

---

**Fim do Relatório de Auditoria**

*Gerado automaticamente por Claude Code em 2026-01-01*
