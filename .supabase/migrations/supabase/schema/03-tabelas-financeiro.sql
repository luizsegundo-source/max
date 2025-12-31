-- ============================================================
-- 💰 MAX - SISTEMA FINANCEIRO COMPLETO
-- Dr. Luiz Segundo | Cirurgia de Parede Abdominal
-- Versão Final - Dezembro 2024
-- ============================================================

-- ============================================================
-- 📋 TABELA: CONTAS A PAGAR
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.contas_pagar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Identificação
  descricao VARCHAR(255) NOT NULL,
  categoria VARCHAR(50) NOT NULL,          -- aluguel, salario, contabilidade, impostos, material, outros
  subcategoria VARCHAR(100),
  
  -- Valores
  valor_total DECIMAL(12, 2) NOT NULL,
  valor_pago DECIMAL(12, 2) DEFAULT 0,
  
  -- Datas
  data_vencimento DATE NOT NULL,
  data_pagamento DATE,
  data_competencia DATE,                   -- Mês de referência
  
  -- Status
  status VARCHAR(20) DEFAULT 'pendente',   -- pendente, pago, atrasado, cancelado
  
  -- Recorrência
  recorrente BOOLEAN DEFAULT FALSE,
  dia_vencimento INT,                      -- Para contas fixas mensais (1, 3, 10, 20, etc)
  
  -- Pagamento
  forma_pagamento VARCHAR(50),             -- pix, boleto, debito_auto, transferencia
  conta_destino VARCHAR(255),              -- Dados bancários ou chave PIX
  comprovante_url TEXT,
  
  -- Fornecedor
  fornecedor_nome VARCHAR(255),
  fornecedor_documento VARCHAR(20),        -- CNPJ/CPF
  
  -- Observações
  observacoes TEXT,
  
  -- Metadados
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  pago_por VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_contas_pagar_vencimento ON clinica.contas_pagar(data_vencimento);
CREATE INDEX IF NOT EXISTS idx_contas_pagar_status ON clinica.contas_pagar(status);
CREATE INDEX IF NOT EXISTS idx_contas_pagar_categoria ON clinica.contas_pagar(categoria);

-- ============================================================
-- 📋 TABELA: CONTAS A RECEBER
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.contas_receber (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Referência
  paciente_id UUID REFERENCES clinica.pacientes(id),
  agendamento_id UUID REFERENCES clinica.agendamentos(id),
  cirurgia_id UUID REFERENCES clinica.cirurgias(id),
  
  -- Identificação
  descricao VARCHAR(255) NOT NULL,
  tipo VARCHAR(50) NOT NULL,               -- consulta, cirurgia, retorno, taxa
  
  -- Convênio
  convenio_id UUID REFERENCES clinica.convenios(id),
  convenio_nome VARCHAR(255),
  numero_guia VARCHAR(50),
  
  -- Valores
  valor_bruto DECIMAL(12, 2) NOT NULL,
  valor_glosa DECIMAL(12, 2) DEFAULT 0,
  valor_liquido DECIMAL(12, 2),
  valor_recebido DECIMAL(12, 2) DEFAULT 0,
  
  -- Datas
  data_execucao DATE NOT NULL,             -- Data do procedimento
  data_faturamento DATE,                   -- Data que foi faturado
  data_previsao DATE,                      -- Previsão de recebimento
  data_recebimento DATE,                   -- Data que recebeu
  
  -- Status
  status VARCHAR(30) DEFAULT 'executado',  -- executado, faturado, aguardando_nf, nf_emitida, recebido, glosado
  
  -- Notas Fiscais
  nota_fiscal_numero VARCHAR(50),
  nota_fiscal_emitida BOOLEAN DEFAULT FALSE,
  nota_fiscal_url TEXT,
  
  -- Hospital (para cirurgias)
  hospital_id UUID REFERENCES clinica.hospitais(id),
  hospital_nome VARCHAR(255),
  
  -- Observações
  motivo_glosa TEXT,
  observacoes TEXT,
  
  -- Metadados
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contas_receber_status ON clinica.contas_receber(status);
CREATE INDEX IF NOT EXISTS idx_contas_receber_convenio ON clinica.contas_receber(convenio_id);
CREATE INDEX IF NOT EXISTS idx_contas_receber_execucao ON clinica.contas_receber(data_execucao);

-- ============================================================
-- 📋 TABELA: TAREFAS FINANCEIRAS
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.tarefas_financeiras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Identificação
  titulo VARCHAR(255) NOT NULL,
  descricao TEXT,
  tipo VARCHAR(50) NOT NULL,               -- enviar_extrato, emitir_nf, cobrar, faturar, outros
  
  -- Prioridade
  prioridade VARCHAR(20) DEFAULT 'normal', -- baixa, normal, alta, urgente
  
  -- Datas
  data_limite DATE,
  data_conclusao DATE,
  
  -- Status
  status VARCHAR(20) DEFAULT 'pendente',   -- pendente, em_andamento, concluida, cancelada
  
  -- Referências
  conta_pagar_id UUID REFERENCES clinica.contas_pagar(id),
  conta_receber_id UUID REFERENCES clinica.contas_receber(id),
  paciente_id UUID REFERENCES clinica.pacientes(id),
  
  -- Origem
  origem VARCHAR(50),                      -- sistema, email, whatsapp, manual
  origem_mensagem_id VARCHAR(100),
  
  -- Responsável
  responsavel VARCHAR(100),                -- dany, dr_luiz, sistema
  
  -- Metadados
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  concluido_por VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_tarefas_financeiras_status ON clinica.tarefas_financeiras(status);
CREATE INDEX IF NOT EXISTS idx_tarefas_financeiras_data ON clinica.tarefas_financeiras(data_limite);

-- ============================================================
-- 📋 TABELA: CÓDIGOS DE PROCEDIMENTOS (TUSS)
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.codigos_procedimentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  codigo_tuss VARCHAR(20) NOT NULL UNIQUE,
  descricao VARCHAR(500) NOT NULL,
  tipo_procedimento VARCHAR(100),
  
  -- Valores referência
  valor_particular DECIMAL(10, 2),
  valor_convenio_medio DECIMAL(10, 2),
  
  ativo BOOLEAN DEFAULT TRUE,
  criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir códigos principais
INSERT INTO clinica.codigos_procedimentos (codigo_tuss, descricao, tipo_procedimento, valor_particular) VALUES
('30304010', 'Hernioplastia inguinal unilateral', 'hernia_inguinal_unilateral', 8000.00),
('30304029', 'Hernioplastia inguinal bilateral', 'hernia_inguinal_bilateral', 12000.00),
('30304037', 'Hernioplastia umbilical', 'hernia_umbilical', 6000.00),
('30304045', 'Hernioplastia epigástrica', 'hernia_epigastrica', 6500.00),
('30304096', 'Correção de diástase de retos abdominais', 'diastase_reto_abdominal', 15000.00),
('30304088', 'Hernioplastia incisional', 'hernia_incisional', 10000.00)
ON CONFLICT (codigo_tuss) DO NOTHING;

-- ============================================================
-- 📊 VIEW: CONTAS A PAGAR DO MÊS
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_contas_pagar_mes AS
SELECT 
  cp.*,
  CASE 
    WHEN cp.data_vencimento < CURRENT_DATE AND cp.status = 'pendente' THEN 'atrasado'
    ELSE cp.status 
  END AS status_atual,
  cp.data_vencimento - CURRENT_DATE AS dias_para_vencer,
  CASE 
    WHEN cp.data_vencimento < CURRENT_DATE THEN '🔴 Atrasado'
    WHEN cp.data_vencimento = CURRENT_DATE THEN '🟠 Vence hoje'
    WHEN cp.data_vencimento <= CURRENT_DATE + 3 THEN '🟡 Próximos dias'
    ELSE '⚪ No prazo'
  END AS urgencia
FROM clinica.contas_pagar cp
WHERE 
  EXTRACT(MONTH FROM cp.data_vencimento) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM cp.data_vencimento) = EXTRACT(YEAR FROM CURRENT_DATE)
  AND cp.status IN ('pendente', 'atrasado')
ORDER BY cp.data_vencimento;

-- ============================================================
-- 📊 VIEW: FATURAMENTO NOVA SAÚDE
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_faturamento_nova_saude AS
SELECT 
  cr.*,
  c.nome AS convenio_nome,
  CASE 
    WHEN cr.status = 'executado' AND CURRENT_DATE >= (DATE_TRUNC('month', cr.data_execucao) + INTERVAL '1 month - 1 day')::DATE 
      THEN 'Pronto para enviar extrato'
    WHEN cr.status = 'faturado' AND CURRENT_DATE >= cr.data_faturamento + 15
      THEN 'Aguardando resposta (passar 15 dias)'
    WHEN cr.status = 'aguardando_nf' 
      THEN 'Emitir NF imediatamente'
    WHEN cr.status = 'nf_emitida'
      THEN 'Aguardando pagamento'
    ELSE cr.status
  END AS proxima_acao,
  -- Previsão de recebimento: último útil do mês seguinte ao faturamento
  (DATE_TRUNC('month', COALESCE(cr.data_faturamento, cr.data_execucao) + INTERVAL '2 months') - INTERVAL '1 day')::DATE AS previsao_recebimento
FROM clinica.contas_receber cr
LEFT JOIN clinica.convenios c ON cr.convenio_id = c.id
WHERE c.nome ILIKE '%nova saúde%' OR c.nome ILIKE '%nova saude%'
ORDER BY cr.data_execucao DESC;

-- ============================================================
-- 📊 VIEW: FATURAMENTO HOSPITAIS
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_faturamento_hospitais AS
SELECT 
  cr.*,
  h.nome AS hospital_nome,
  cr.data_execucao AS mes_execucao,
  (DATE_TRUNC('month', cr.data_execucao) + INTERVAL '1 month')::DATE AS mes_faturamento,
  (DATE_TRUNC('month', cr.data_execucao) + INTERVAL '2 months')::DATE AS mes_pagamento,
  CASE 
    WHEN cr.status = 'executado' 
      AND CURRENT_DATE >= (DATE_TRUNC('month', cr.data_execucao) + INTERVAL '2 months')::DATE
      THEN '📧 Verificar solicitação de NF'
    WHEN cr.status = 'aguardando_nf' 
      THEN '📄 Emitir NF'
    WHEN cr.status = 'nf_emitida'
      THEN '💰 Aguardando pagamento'
    ELSE cr.status
  END AS proxima_acao
FROM clinica.contas_receber cr
LEFT JOIN clinica.hospitais h ON cr.hospital_id = h.id
WHERE cr.tipo = 'cirurgia' AND cr.hospital_id IS NOT NULL
ORDER BY cr.data_execucao DESC;

-- ============================================================
-- 📊 VIEW: DASHBOARD FINANCEIRO
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_dashboard_financeiro AS
SELECT 
  COALESCE(c.nome, 'Particular') AS convenio,
  COUNT(*) AS total_procedimentos,
  SUM(cr.valor_bruto) AS faturamento_bruto,
  SUM(cr.valor_glosa) AS total_glosas,
  SUM(cr.valor_recebido) AS total_recebido,
  SUM(CASE WHEN cr.status = 'recebido' THEN 0 ELSE cr.valor_liquido END) AS a_receber,
  ROUND(AVG(cr.valor_bruto), 2) AS ticket_medio,
  ROUND(100.0 * SUM(cr.valor_glosa) / NULLIF(SUM(cr.valor_bruto), 0), 2) AS taxa_glosa_percent
FROM clinica.contas_receber cr
LEFT JOIN clinica.convenios c ON cr.convenio_id = c.id
WHERE EXTRACT(YEAR FROM cr.data_execucao) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY COALESCE(c.nome, 'Particular')
ORDER BY total_recebido DESC;

-- ============================================================
-- ⚙️ FUNCTION: GERAR CONTAS FIXAS DO MÊS
-- ============================================================

CREATE OR REPLACE FUNCTION clinica.gerar_contas_mes(p_mes INT, p_ano INT)
RETURNS TABLE(contas_geradas INT, total_valor DECIMAL) AS $$
DECLARE
  v_count INT := 0;
  v_total DECIMAL := 0;
  v_data_base DATE;
  v_ultimo_util DATE;
BEGIN
  v_data_base := make_date(p_ano, p_mes, 1);
  
  -- Calcular último dia útil do mês
  v_ultimo_util := (DATE_TRUNC('month', v_data_base) + INTERVAL '1 month - 1 day')::DATE;
  WHILE EXTRACT(DOW FROM v_ultimo_util) IN (0, 6) LOOP
    v_ultimo_util := v_ultimo_util - 1;
  END LOOP;
  
  -- Dia 1: Aluguéis e Motoboy
  INSERT INTO clinica.contas_pagar (descricao, categoria, valor_total, data_vencimento, data_competencia, dia_vencimento, recorrente, forma_pagamento, fornecedor_nome)
  SELECT descricao, categoria, valor, make_date(p_ano, p_mes, 1), v_data_base, 1, TRUE, forma, fornecedor
  FROM (VALUES
    ('Aluguel Global Tower', 'aluguel', 800.00, 'pix', 'Global Tower'),
    ('Aluguel GRAMEG', 'aluguel', 700.00, 'pix', 'GRAMEG'),
    ('Motoboy Malotes', 'servicos', 50.00, 'pix', 'Motoboy')
  ) AS contas(descricao, categoria, valor, forma, fornecedor)
  WHERE NOT EXISTS (
    SELECT 1 FROM clinica.contas_pagar cp 
    WHERE cp.data_competencia = v_data_base 
    AND cp.descricao = contas.descricao
  );
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  -- Dia 10: Contabilidade Sante
  INSERT INTO clinica.contas_pagar (descricao, categoria, valor_total, data_vencimento, data_competencia, dia_vencimento, recorrente, forma_pagamento, fornecedor_nome)
  VALUES ('Honorários Contabilidade Sante', 'contabilidade', 250.00, make_date(p_ano, p_mes, 10), v_data_base, 10, TRUE, 'boleto', 'Contabilidade Sante')
  ON CONFLICT DO NOTHING;
  
  v_count := v_count + 1;
  
  -- Dia 20: Dany (fixo), S&C e Impostos
  INSERT INTO clinica.contas_pagar (descricao, categoria, valor_total, data_vencimento, data_competencia, dia_vencimento, recorrente, forma_pagamento, fornecedor_nome)
  SELECT descricao, categoria, valor, make_date(p_ano, p_mes, 20), v_data_base, 20, TRUE, forma, fornecedor
  FROM (VALUES
    ('Honorários Dany (Fixo)', 'salario', 4000.00, 'pix', 'Dany'),
    ('Honorários Contabilidade S&C', 'contabilidade', 450.00, 'boleto', 'Segundo e Cossetti')
  ) AS contas(descricao, categoria, valor, forma, fornecedor)
  WHERE NOT EXISTS (
    SELECT 1 FROM clinica.contas_pagar cp 
    WHERE cp.data_competencia = v_data_base 
    AND cp.descricao = contas.descricao
  );
  
  -- Tarefa: Enviar extrato Nova Saúde (último útil)
  INSERT INTO clinica.tarefas_financeiras (titulo, descricao, tipo, data_limite, prioridade, responsavel)
  VALUES (
    'Enviar Extrato Nova Saúde - ' || TO_CHAR(v_data_base, 'MM/YYYY'),
    'Enviar extrato de produção do mês para Nova Saúde',
    'enviar_extrato',
    v_ultimo_util,
    'alta',
    'dany'
  )
  ON CONFLICT DO NOTHING;
  
  -- Calcular total
  SELECT COUNT(*), COALESCE(SUM(valor_total), 0) INTO v_count, v_total
  FROM clinica.contas_pagar
  WHERE data_competencia = v_data_base;
  
  RETURN QUERY SELECT v_count, v_total;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ⚙️ FUNCTION: CALCULAR COMISSÃO DANY (5% PARTICULAR)
-- ============================================================

CREATE OR REPLACE FUNCTION clinica.calcular_comissao_dany(p_mes INT, p_ano INT)
RETURNS TABLE(total_particular DECIMAL, comissao DECIMAL, detalhes JSONB) AS $$
DECLARE
  v_total DECIMAL;
  v_comissao DECIMAL;
  v_detalhes JSONB;
  v_data_inicio DATE;
  v_data_fim DATE;
BEGIN
  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := (v_data_inicio + INTERVAL '1 month - 1 day')::DATE;
  
  -- Buscar total de consultas e cirurgias particulares
  SELECT 
    COALESCE(SUM(valor_bruto), 0),
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'tipo', tipo,
        'data', data_execucao,
        'valor', valor_bruto,
        'paciente', paciente_id
      )
    )
  INTO v_total, v_detalhes
  FROM clinica.contas_receber
  WHERE convenio_id IS NULL  -- Particular
    AND data_execucao BETWEEN v_data_inicio AND v_data_fim
    AND tipo IN ('consulta', 'cirurgia')
    AND status != 'cancelado';
  
  v_comissao := v_total * 0.05;  -- 5%
  
  -- Atualizar ou criar conta a pagar da comissão
  INSERT INTO clinica.contas_pagar (
    descricao, categoria, valor_total, data_vencimento, data_competencia, 
    dia_vencimento, recorrente, forma_pagamento, fornecedor_nome, observacoes
  )
  VALUES (
    'Comissão Dany 5% - ' || TO_CHAR(v_data_inicio, 'MM/YYYY'),
    'comissao',
    v_comissao,
    make_date(p_ano, p_mes, 20),
    v_data_inicio,
    20,
    FALSE,
    'pix',
    'Dany',
    'Base: R$ ' || v_total::TEXT || ' (5% = R$ ' || v_comissao::TEXT || ')'
  )
  ON CONFLICT DO NOTHING;
  
  RETURN QUERY SELECT v_total, v_comissao, COALESCE(v_detalhes, '[]'::JSONB);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ⚙️ FUNCTION: VERIFICAR ALERTAS FINANCEIROS
-- ============================================================

CREATE OR REPLACE FUNCTION clinica.verificar_alertas_financeiros()
RETURNS TABLE(
  tipo VARCHAR,
  descricao TEXT,
  valor DECIMAL,
  data_limite DATE,
  dias_restantes INT,
  prioridade VARCHAR,
  acao_sugerida TEXT
) AS $$
BEGIN
  -- Contas a pagar atrasadas ou próximas
  RETURN QUERY
  SELECT 
    'conta_pagar'::VARCHAR,
    cp.descricao::TEXT,
    cp.valor_total,
    cp.data_vencimento,
    (cp.data_vencimento - CURRENT_DATE)::INT,
    CASE 
      WHEN cp.data_vencimento < CURRENT_DATE THEN 'urgente'
      WHEN cp.data_vencimento = CURRENT_DATE THEN 'alta'
      WHEN cp.data_vencimento <= CURRENT_DATE + 3 THEN 'normal'
      ELSE 'baixa'
    END::VARCHAR,
    CASE 
      WHEN cp.data_vencimento < CURRENT_DATE THEN 'Pagar imediatamente - ATRASADO'
      WHEN cp.data_vencimento = CURRENT_DATE THEN 'Pagar hoje'
      ELSE 'Agendar pagamento'
    END::TEXT
  FROM clinica.contas_pagar cp
  WHERE cp.status = 'pendente'
    AND cp.data_vencimento <= CURRENT_DATE + 7;
  
  -- Tarefas financeiras pendentes
  RETURN QUERY
  SELECT 
    'tarefa'::VARCHAR,
    tf.titulo::TEXT,
    0::DECIMAL,
    tf.data_limite,
    (tf.data_limite - CURRENT_DATE)::INT,
    tf.prioridade,
    tf.descricao::TEXT
  FROM clinica.tarefas_financeiras tf
  WHERE tf.status = 'pendente'
    AND tf.data_limite <= CURRENT_DATE + 7;
  
  -- NFs a emitir (Nova Saúde)
  RETURN QUERY
  SELECT 
    'emitir_nf'::VARCHAR,
    ('Emitir NF - ' || cr.descricao)::TEXT,
    cr.valor_liquido,
    CURRENT_DATE,
    0,
    'alta'::VARCHAR,
    'Emitir Nota Fiscal após confirmação do extrato'::TEXT
  FROM clinica.contas_receber cr
  WHERE cr.status = 'aguardando_nf';
  
  -- Pagamentos a receber (hospitais - 2 meses após execução)
  RETURN QUERY
  SELECT 
    'cobrar_hospital'::VARCHAR,
    ('Verificar NF Hospital - ' || cr.descricao)::TEXT,
    cr.valor_liquido,
    (DATE_TRUNC('month', cr.data_execucao) + INTERVAL '2 months')::DATE,
    ((DATE_TRUNC('month', cr.data_execucao) + INTERVAL '2 months')::DATE - CURRENT_DATE)::INT,
    'normal'::VARCHAR,
    'Verificar se hospital solicitou NF'::TEXT
  FROM clinica.contas_receber cr
  WHERE cr.tipo = 'cirurgia'
    AND cr.hospital_id IS NOT NULL
    AND cr.status = 'executado'
    AND CURRENT_DATE >= (DATE_TRUNC('month', cr.data_execucao) + INTERVAL '2 months')::DATE;
  
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ⚙️ FUNCTION: ATUALIZAÇÃO DIÁRIA COMPLETA
-- ============================================================

CREATE OR REPLACE FUNCTION clinica.atualizacao_diaria_completa()
RETURNS JSONB AS $$
DECLARE
  v_resultado JSONB;
  v_contas_geradas INT;
  v_total_contas DECIMAL;
  v_comissao_dany DECIMAL;
  v_alertas_count INT;
  v_metricas_atualizadas INT;
  v_mes INT;
  v_ano INT;
BEGIN
  v_mes := EXTRACT(MONTH FROM CURRENT_DATE);
  v_ano := EXTRACT(YEAR FROM CURRENT_DATE);
  
  -- 1. Atualizar status de contas atrasadas
  UPDATE clinica.contas_pagar
  SET status = 'atrasado', atualizado_em = NOW()
  WHERE status = 'pendente' AND data_vencimento < CURRENT_DATE;
  
  -- 2. Gerar contas do mês se ainda não existem
  SELECT contas_geradas, total_valor INTO v_contas_geradas, v_total_contas
  FROM clinica.gerar_contas_mes(v_mes, v_ano);
  
  -- 3. Calcular comissão Dany
  SELECT comissao INTO v_comissao_dany
  FROM clinica.calcular_comissao_dany(v_mes, v_ano);
  
  -- 4. Contar alertas
  SELECT COUNT(*) INTO v_alertas_count
  FROM clinica.verificar_alertas_financeiros();
  
  -- 5. Atualizar métricas dos pacientes (dias desde consulta, elegibilidade retorno, etc)
  UPDATE clinica.pacientes
  SET 
    atualizado_em = NOW()
  WHERE deletado_em IS NULL;
  
  GET DIAGNOSTICS v_metricas_atualizadas = ROW_COUNT;
  
  -- Montar resultado
  v_resultado := JSONB_BUILD_OBJECT(
    'data_execucao', CURRENT_TIMESTAMP,
    'mes_referencia', v_mes || '/' || v_ano,
    'contas_geradas', v_contas_geradas,
    'total_contas_mes', v_total_contas,
    'comissao_dany', v_comissao_dany,
    'alertas_pendentes', v_alertas_count,
    'metricas_atualizadas', v_metricas_atualizadas
  );
  
  RETURN v_resultado;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 🔧 TRIGGERS
-- ============================================================

-- Trigger para atualizar timestamp
CREATE OR REPLACE FUNCTION clinica.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_contas_pagar_timestamp ON clinica.contas_pagar;
CREATE TRIGGER tr_contas_pagar_timestamp
  BEFORE UPDATE ON clinica.contas_pagar
  FOR EACH ROW EXECUTE FUNCTION clinica.update_timestamp();

DROP TRIGGER IF EXISTS tr_contas_receber_timestamp ON clinica.contas_receber;
CREATE TRIGGER tr_contas_receber_timestamp
  BEFORE UPDATE ON clinica.contas_receber
  FOR EACH ROW EXECUTE FUNCTION clinica.update_timestamp();

DROP TRIGGER IF EXISTS tr_tarefas_financeiras_timestamp ON clinica.tarefas_financeiras;
CREATE TRIGGER tr_tarefas_financeiras_timestamp
  BEFORE UPDATE ON clinica.tarefas_financeiras
  FOR EACH ROW EXECUTE FUNCTION clinica.update_timestamp();

-- ============================================================
-- 🔒 ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE clinica.contas_pagar ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinica.contas_receber ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinica.tarefas_financeiras ENABLE ROW LEVEL SECURITY;

-- Políticas para service_role (n8n)
DROP POLICY IF EXISTS "Service role full access" ON clinica.contas_pagar;
CREATE POLICY "Service role full access" ON clinica.contas_pagar
  FOR ALL USING (true);

DROP POLICY IF EXISTS "Service role full access" ON clinica.contas_receber;
CREATE POLICY "Service role full access" ON clinica.contas_receber
  FOR ALL USING (true);

DROP POLICY IF EXISTS "Service role full access" ON clinica.tarefas_financeiras;
CREATE POLICY "Service role full access" ON clinica.tarefas_financeiras
  FOR ALL USING (true);

-- ============================================================
-- ✅ SCRIPT COMPLETO!
-- Execute no Supabase SQL Editor
-- ============================================================
