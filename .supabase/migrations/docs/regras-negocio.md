# 📋 Regras de Negócio - MAX

## 🏥 Atendimento

### Locais e Horários
- **Global Tower (Vitória)**: Quartas 08:00-12:00
  - Convênios: Unimed, Nova Saúde, Particular
- **GRAMEG (Vila Velha)**: Quintas 08:00-12:00
  - Convênios: Todos

### Duração de Consultas
- Consulta padrão: 30 minutos
- Retorno: 20 minutos
- Pré-operatório: 45 minutos

---

## 💰 Valores

### Consulta
| Tipo | Valor |
|------|-------|
| Particular | R$ 600,00 |
| Retorno (até 30 dias) - Convênio | Gratuito |
| Retorno (após 30 dias) - Particular | R$ 300,00 (cortesia) |

### Cirurgias (Particular - Base)
| Procedimento | Código TUSS | Valor Base |
|--------------|-------------|------------|
| Hérnia inguinal unilateral | 30304010 | R$ 8.000 |
| Hérnia inguinal bilateral | 30304029 | R$ 12.000 |
| Hérnia umbilical | 30304037 | R$ 6.000 |
| Hérnia epigástrica | 30304045 | R$ 6.500 |
| Hérnia incisional | 30304088 | R$ 10.000 |
| Diástase de retos | 30304096 | R$ 15.000 |

---

## 📅 Calendário de Pagamentos

| Dia | Descrição | Valor | Forma |
|-----|-----------|-------|-------|
| 1 | Aluguel Global Tower | R$ 800 | PIX |
| 1 | Aluguel GRAMEG | R$ 700 | PIX |
| 1 | Motoboy | R$ 50 | PIX |
| 3 | Cartões (Apps/Anúncios) | Variável | Débito Auto |
| 10 | Contabilidade Sante | R$ 250 | Boleto |
| 20 | Dany (Fixo) | R$ 4.000 | PIX |
| 20 | Dany (Comissão 5%) | Variável | PIX |
| 20 | Contabilidade S&C | R$ 450 | Boleto |
| 20 | Impostos | Variável | Boleto |
| Último útil | Extrato Nova Saúde | - | Email |

---

## 🔄 Ciclos de Faturamento

### Nova Saúde
```
Mês N: Execução
  ↓
Último útil: Enviar extrato
  ↓
Até dia 15 (N+1): Resposta (OK/Glosas)
  ↓
Imediatamente: Emitir NF
  ↓
Último útil (N+1): Receber pagamento
```

### Hospitais
```
Mês N: Execução da cirurgia
  ↓
Mês N+1: Hospital fatura
  ↓
Mês N+2: Solicitação de NF
  ↓
Último útil (N+2): Pagamento
```

---

## 👩‍💼 Comissão Dany

- **Fixo**: R$ 4.000/mês
- **Variável**: 5% sobre consultas e cirurgias **PARTICULARES**
- **Vencimento**: Dia 20
- **Cálculo**: `(total_consultas_particular + total_cirurgias_particular) * 0.05`

---

## 📱 Regras do Agendamento via WhatsApp

### Estratégia de Oferta
1. **Primeira oferta**: UM horário específico
   - "Que tal quarta às 09:30?"
2. **Se recusar**: Máximo 2-3 alternativas
3. **Horários preferidos**: 09:30, 10:00, 09:00, 10:30

### Limites
- Busca inicial: 3 semanas
- Busca máxima: 3 meses
- Máximo de perguntas antes de agendar: 2-3

### Feriados Bloqueados (2025-2026)
- 01/01 - Confraternização
- Carnaval (seg/ter)
- Sexta-feira Santa
- 21/04 - Tiradentes
- 01/05 - Trabalho
- Corpus Christi
- 07/09 - Independência
- 12/10 - N.S. Aparecida
- 02/11 - Finados
- 15/11 - Proclamação
- 25/12 - Natal
- 31/12 - Réveillon

---

## 🔔 Alertas Automáticos

| Situação | Prioridade | Ação |
|----------|------------|------|
| Conta atrasada | 🔴 Urgente | WhatsApp imediato |
| Vence hoje | 🟠 Alta | WhatsApp manhã (6h) |
| Vence em 1-3 dias | 🟡 Normal | Incluir no resumo |
| Vence em 4-7 dias | ⚪ Baixa | Dashboard apenas |

---

## 📄 Documentos Automáticos

### Gerados pelo Sistema
- Guia SADT
- Guia de Internação
- Atestado Médico
- Receituário (Memed)
- Contrato Particular
- Termo de Consentimento

### Assinatura Digital (D4Sign)
- Ambiente: Sandbox (testes) / Produção
- Cofre: Documentos Médicos
- Fluxo: Upload → Signatário → Enviar → Callback → Confirmar

---

## 🚨 Escalação para Humano

### Quando MAX escala para Dany
- Confiança < 65%
- Assunto financeiro/valores
- Reclamação
- Pedido de hospital/guia
- Urgência médica
- Dúvida sobre procedimento

### Bloqueio do Bot
- Duração padrão: 4 horas
- Comando: `/bloquear [telefone]`
- Desbloqueio: `/desbloquear [telefone]`
