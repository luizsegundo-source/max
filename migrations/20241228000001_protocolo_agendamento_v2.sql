-- ============================================================
-- MAX - ATUALIZAÇÃO DO BANCO DE DADOS
-- Protocolo de Agendamento v2.0
-- Data: 28/12/2024
-- ============================================================

-- ============================================================
-- 1. ATUALIZAR TABELA DE CONVÊNIOS (SEGURO - SEM TRUNCATE)
-- ============================================================

-- Garantir que codigo é único (para ON CONFLICT funcionar)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'convenios_codigo_unique'
    ) THEN
        ALTER TABLE clinica.convenios ADD CONSTRAINT convenios_codigo_unique UNIQUE (codigo);
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignora se já existir
END $$;

-- Inserir convênios novos (não apaga existentes)
INSERT INTO clinica.convenios (nome, codigo, ativo) VALUES
-- Aceitos em Vitória + Vila Velha
('Unimed Personal', 'UNIMED_PERSONAL', true),
('Unimed Intercâmbio', 'UNIMED_INTERCAMBIO', true),
('Unimed Vitória', 'UNIMED_VITORIA', true),
('Nova Saúde', 'NOVA_SAUDE', true),
('Mais Saúde', 'MAIS_SAUDE', true),
('Particular', 'PARTICULAR', true),

-- Aceitos APENAS em Vila Velha (Grameg)
('ASSEFAZ', 'ASSEFAZ', true),
('AMIL', 'AMIL', true),
('BANESCAIXA', 'BANESCAIXA', true),
('Bradesco', 'BRADESCO', true),
('CAPSESP', 'CAPSESP', true),
('CASSI', 'CASSI', true),
('CESAN', 'CESAN', true),
('Postal Saúde', 'POSTAL_SAUDE', true),
('Saúde Caixa', 'SAUDE_CAIXA', true),
('Sul América', 'SULAMERICA', true),
('Vale/PASA', 'VALE_PASA', true)
ON CONFLICT (codigo) DO UPDATE SET nome = EXCLUDED.nome, ativo = EXCLUDED.ativo;

-- ============================================================
-- 2. ATUALIZAR TABELA DE HOSPITAIS/LOCAIS (SEGURO)
-- ============================================================

-- Adicionar coluna tipo se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'clinica' 
                   AND table_name = 'hospitais' 
                   AND column_name = 'tipo') THEN
        ALTER TABLE clinica.hospitais ADD COLUMN tipo VARCHAR(50);
    END IF;
END $$;

-- Garantir constraint unique no apelido
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'hospitais_apelido_unique'
    ) THEN
        ALTER TABLE clinica.hospitais ADD CONSTRAINT hospitais_apelido_unique UNIQUE (apelido);
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- Inserir/atualizar hospitais
INSERT INTO clinica.hospitais (nome, apelido, cidade, endereco, tipo, ativo) VALUES
('Global Tower', 'Global Tower', 'Vitória', 
 'Av. Nossa Senhora da Penha, 2190 - Santa Lucia, Vitória/ES', 
 'consultorio', true),
 
('Grameg', 'Grameg', 'Vila Velha', 
 'Rua XXX, Vila Velha/ES', 
 'clinica_cc', true),
 
('Clínica A2', 'A2', 'Vitória', 
 'Próximo ao Global Tower', 
 'consultorio_parceiro', true),
 
('Hospital Meridional', 'Meridional', 'Cariacica', 
 'Rodovia BR-262, KM 0 - Campo Grande, Cariacica/ES', 
 'hospital', true)
ON CONFLICT (apelido) DO UPDATE SET 
    nome = EXCLUDED.nome,
    cidade = EXCLUDED.cidade,
    endereco = EXCLUDED.endereco,
    tipo = EXCLUDED.tipo,
    ativo = EXCLUDED.ativo;

-- ============================================================
-- 3. CRIAR TABELA: CONVENIOS_LOCAIS (onde cada convênio atende)
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.convenios_locais (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    convenio_id UUID REFERENCES clinica.convenios(id) ON DELETE CASCADE,
    local_id UUID REFERENCES clinica.hospitais(id) ON DELETE CASCADE,
    valor_consulta DECIMAL(10,2) NOT NULL,
    valor_retorno DECIMAL(10,2) DEFAULT 0,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(convenio_id, local_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_convenios_locais_convenio ON clinica.convenios_locais(convenio_id);
CREATE INDEX IF NOT EXISTS idx_convenios_locais_local ON clinica.convenios_locais(local_id);

-- ============================================================
-- 4. POPULAR CONVENIOS_LOCAIS COM VALORES
-- ============================================================

-- Primeiro, vamos criar uma função auxiliar para facilitar
CREATE OR REPLACE FUNCTION clinica.inserir_convenio_local(
    p_convenio_codigo VARCHAR,
    p_local_apelido VARCHAR,
    p_valor DECIMAL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO clinica.convenios_locais (convenio_id, local_id, valor_consulta)
    SELECT c.id, h.id, p_valor
    FROM clinica.convenios c, clinica.hospitais h
    WHERE c.codigo = p_convenio_codigo 
    AND h.apelido = p_local_apelido
    ON CONFLICT (convenio_id, local_id) 
    DO UPDATE SET valor_consulta = p_valor, atualizado_em = NOW();
END;
$$ LANGUAGE plpgsql;

-- Popular valores

-- VITÓRIA (Global Tower)
SELECT clinica.inserir_convenio_local('UNIMED_PERSONAL', 'Global Tower', 81.67);
SELECT clinica.inserir_convenio_local('UNIMED_INTERCAMBIO', 'Global Tower', 122.00);
SELECT clinica.inserir_convenio_local('UNIMED_VITORIA', 'Global Tower', 130.00);
SELECT clinica.inserir_convenio_local('NOVA_SAUDE', 'Global Tower', 80.00);
SELECT clinica.inserir_convenio_local('MAIS_SAUDE', 'Global Tower', 80.00);
SELECT clinica.inserir_convenio_local('PARTICULAR', 'Global Tower', 600.00);

-- VILA VELHA (Grameg) - mesmos de Vitória
SELECT clinica.inserir_convenio_local('UNIMED_PERSONAL', 'Grameg', 81.67);
SELECT clinica.inserir_convenio_local('UNIMED_INTERCAMBIO', 'Grameg', 122.00);
SELECT clinica.inserir_convenio_local('UNIMED_VITORIA', 'Grameg', 130.00);
SELECT clinica.inserir_convenio_local('NOVA_SAUDE', 'Grameg', 80.00);
SELECT clinica.inserir_convenio_local('MAIS_SAUDE', 'Grameg', 80.00);
SELECT clinica.inserir_convenio_local('PARTICULAR', 'Grameg', 600.00);

-- VILA VELHA (Grameg) - convênios exclusivos
SELECT clinica.inserir_convenio_local('BRADESCO', 'Grameg', 131.50);
SELECT clinica.inserir_convenio_local('VALE_PASA', 'Grameg', 102.52);
SELECT clinica.inserir_convenio_local('CASSI', 'Grameg', 100.46);
SELECT clinica.inserir_convenio_local('SAUDE_CAIXA', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('ASSEFAZ', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('AMIL', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('BANESCAIXA', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('CAPSESP', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('CESAN', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('POSTAL_SAUDE', 'Grameg', 110.00);
SELECT clinica.inserir_convenio_local('SULAMERICA', 'Grameg', 110.00);

-- CLÍNICA A2 - Apenas Nova Saúde com valor diferenciado
SELECT clinica.inserir_convenio_local('NOVA_SAUDE', 'A2', 55.00);

-- ============================================================
-- 5. CRIAR TABELA: PENDENCIAS_PREOP
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.pendencias_preop (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    paciente_id UUID REFERENCES clinica.pacientes(id) ON DELETE CASCADE,
    cirurgia_id UUID REFERENCES clinica.cirurgias(id) ON DELETE SET NULL,
    
    -- Tipo de pendência
    tipo VARCHAR(100) NOT NULL,
    descricao TEXT,
    
    -- Status
    status VARCHAR(30) DEFAULT 'pendente', -- pendente, concluida, cancelada
    
    -- Resolução
    documento_id UUID REFERENCES clinica.documentos(id),
    resolvido_por VARCHAR(50), -- 'documento', 'confirmacao_texto', 'manual'
    resolvido_em TIMESTAMPTZ,
    observacao_resolucao TEXT,
    
    -- Controle
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_por UUID REFERENCES clinica.usuarios(id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_pendencias_paciente ON clinica.pendencias_preop(paciente_id);
CREATE INDEX IF NOT EXISTS idx_pendencias_status ON clinica.pendencias_preop(status);
CREATE INDEX IF NOT EXISTS idx_pendencias_cirurgia ON clinica.pendencias_preop(cirurgia_id);

-- ============================================================
-- 6. CRIAR TABELA: ACOMPANHANTES
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.acompanhantes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    paciente_id UUID REFERENCES clinica.pacientes(id) ON DELETE CASCADE,
    cirurgia_id UUID REFERENCES clinica.cirurgias(id) ON DELETE SET NULL,
    
    -- Dados
    nome VARCHAR(255),
    telefone VARCHAR(20) NOT NULL,
    parentesco VARCHAR(50),
    
    -- Comunicação
    notificar_inicio BOOLEAN DEFAULT TRUE,
    notificar_fim BOOLEAN DEFAULT TRUE,
    
    -- Controle
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_acompanhantes_paciente ON clinica.acompanhantes(paciente_id);
CREATE INDEX IF NOT EXISTS idx_acompanhantes_cirurgia ON clinica.acompanhantes(cirurgia_id);
CREATE INDEX IF NOT EXISTS idx_acompanhantes_telefone ON clinica.acompanhantes(telefone);

-- ============================================================
-- 7. ATUALIZAR TABELA: PACIENTES
-- ============================================================

-- Adicionar novos campos
ALTER TABLE clinica.pacientes 
ADD COLUMN IF NOT EXISTS ultima_consulta_em TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS stand_by BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS stand_by_em TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS followup_nivel INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS ultimo_followup_em TIMESTAMPTZ;

-- Função para calcular dias desde última consulta
CREATE OR REPLACE FUNCTION clinica.dias_desde_consulta(p_paciente_id UUID)
RETURNS INT AS $$
DECLARE
    v_dias INT;
BEGIN
    SELECT EXTRACT(DAY FROM NOW() - ultima_consulta_em)::INT
    INTO v_dias
    FROM clinica.pacientes
    WHERE id = p_paciente_id;
    
    RETURN COALESCE(v_dias, 999);
END;
$$ LANGUAGE plpgsql;

-- Função para verificar se é retorno
CREATE OR REPLACE FUNCTION clinica.e_retorno(p_paciente_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN clinica.dias_desde_consulta(p_paciente_id) < 30;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 8. ATUALIZAR TABELA: AGENDAMENTOS
-- ============================================================

ALTER TABLE clinica.agendamentos
ADD COLUMN IF NOT EXISTS valor_previsto DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS tipo_consulta VARCHAR(30), -- primeira, retorno, retorno_preop, retorno_posop
ADD COLUMN IF NOT EXISTS e_retorno BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS confirmado_pelo_paciente BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS confirmacao_enviada_24h BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS confirmacao_enviada_2h BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS faltou BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS mensagem_pos_enviada BOOLEAN DEFAULT FALSE;

-- ============================================================
-- 9. ATUALIZAR TABELA: CIRURGIAS
-- ============================================================

ALTER TABLE clinica.cirurgias
ADD COLUMN IF NOT EXISTS data_alta_hospitalar TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS hora_inicio_real TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS hora_fim_real TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS duracao_minutos_real INT,
ADD COLUMN IF NOT EXISTS lembrete_3dias_enviado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS lembrete_1dia_enviado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS lembrete_60min_enviado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS aviso_fim_enviado BOOLEAN DEFAULT FALSE;

-- ============================================================
-- 10. CRIAR TABELA: MENSAGENS_AUTOMATICAS (Templates)
-- ============================================================

CREATE TABLE IF NOT EXISTS clinica.mensagens_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo VARCHAR(50) UNIQUE NOT NULL, -- CONF_24H, CONF_2H, etc
    nome VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL, -- confirmacao, followup, cirurgia, posop
    template TEXT NOT NULL,
    
    -- Variáveis disponíveis (para documentação)
    variaveis_disponiveis TEXT[],
    
    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Popular templates iniciais
INSERT INTO clinica.mensagens_templates (codigo, nome, categoria, template, variaveis_disponiveis) VALUES

-- Confirmações
('CONF_24H', 'Confirmação 24h antes', 'confirmacao',
'Olá, {{nome}}! 😊

Lembrando da sua consulta amanhã:

📅 {{dia_semana}}, {{data}}
⏰ {{horario}}
📍 {{local}}

Confirma presença? Responda SIM ou se precisar remarcar, me avise!',
ARRAY['nome', 'dia_semana', 'data', 'horario', 'local', 'endereco']),

('CONF_2H', 'Confirmação 2h antes', 'confirmacao',
'Olá, {{nome}}!

Sua consulta é daqui a 2 horas.

📍 {{endereco}}
🗺️ {{link_maps}}

Até logo! 🙂',
ARRAY['nome', 'endereco', 'link_maps']),

-- Pós-agendamento
('POSAGEND', 'Pós-agendamento imediato', 'confirmacao',
'Consulta confirmada! ✅

📅 {{dia_semana}}, {{data}} às {{horario}}
📍 {{local}}

Quer que eu envie a localização no mapa? 🗺️

💡 Se quiser, pode me enviar:
- Foto da carteirinha do plano
- Exames anteriores
- Lista de medicações que usa

Tudo será avaliado na consulta com o Dr. Luiz. 😊',
ARRAY['nome', 'dia_semana', 'data', 'horario', 'local']),

-- Pós-consulta
('POSCONS_30MIN', 'Pós-consulta 30min', 'posconsulta',
'{{nome}}, foi um prazer te atender! 🙂

Se puder, sua avaliação significa muito:
⭐ {{link_google}}

Ficou alguma dúvida? Estou por aqui!',
ARRAY['nome', 'link_google']),

-- Follow-up
('FOLLOW_1D', 'Follow-up 1 dia', 'followup',
'Oi, {{nome}}! 

Vi que não conseguimos finalizar o agendamento.
Ainda posso ajudar? 😊',
ARRAY['nome']),

('FOLLOW_3D', 'Follow-up 3 dias', 'followup',
'Olá, {{nome}}!

Os horários estão indo rápido...
Quer que eu reserve um para você?',
ARRAY['nome']),

('FOLLOW_7D', 'Follow-up 7 dias', 'followup',
'{{nome}}, tudo bem?

Vou deixar seus dados guardados.
Quando quiser agendar, é só me chamar! 🙂',
ARRAY['nome']),

-- Faltou
('FALTOU', 'Paciente faltou', 'followup',
'Olá, {{nome}}!

Sentimos sua falta hoje na consulta.
Aconteceu alguma coisa?

Quer remarcar para outro dia? 📅',
ARRAY['nome']),

-- Cirurgia
('CX_3DIAS', 'Cirurgia 3 dias antes', 'cirurgia',
'{{nome}}, faltam 3 dias! 💪

Tudo caminhando bem para sua cirurgia.

Amanhã vou te enviar um checklist com tudo que precisa levar, ok?

Vai dar tudo certo! 🙏',
ARRAY['nome']),

('CX_1DIA', 'Cirurgia 1 dia antes (paciente)', 'cirurgia',
'{{nome}}, amanhã é o grande dia! 🙏

📋 **Checklist para levar:**
- Documento com foto
- Carteirinha do convênio
- Todos os exames
- Laudos das consultas

🏥 **Hospital:** {{hospital}}
📍 **Endereço:** {{endereco_hospital}}
⏰ **Chegada:** {{horario_chegada}}

📞 Por favor, me passa o telefone de um acompanhante para eu manter contato no dia da cirurgia.

Vai dar tudo certo! 💙',
ARRAY['nome', 'hospital', 'endereco_hospital', 'horario_chegada']),

('CX_1DIA_EQUIPE', 'Cirurgia 1 dia antes (equipe)', 'cirurgia',
'🔔 LEMBRETE DE CIRURGIA - AMANHÃ

👤 Paciente: {{paciente_nome}}
🔪 Procedimento: {{procedimento}}
🏥 Hospital: {{hospital}}
⏰ Horário: {{horario}}

👥 Equipe confirmada

Bora, {{nome_membro}}! 💪',
ARRAY['paciente_nome', 'procedimento', 'hospital', 'horario', 'nome_membro']),

('CX_60MIN', 'Cirurgia 60min antes', 'cirurgia',
'Daqui a 1 hora! 🙏

{{paciente_nome}} - {{procedimento}}

Que Deus abençoe as mãos de todos. Vai dar tudo certo!',
ARRAY['paciente_nome', 'procedimento']),

('CX_60MIN_ACOMP', 'Cirurgia 60min (acompanhante)', 'cirurgia',
'Olá! A cirurgia de {{paciente_nome}} começa em 1 hora.

Fique tranquilo(a), a equipe é excelente e tudo vai correr bem!

Te aviso assim que terminar. 💙',
ARRAY['paciente_nome']),

('CX_FIM_ACOMP', 'Cirurgia fim (acompanhante)', 'cirurgia',
'Boa notícia! 🎉

A cirurgia de {{paciente_nome}} terminou e correu tudo bem!

Agora {{pronome}} vai para a recuperação pós-anestésica e logo estará indo para o quarto.

Em breve vocês se encontram! 💙',
ARRAY['paciente_nome', 'pronome']),

-- Alta
('ALTA_RETORNO', 'Alta hospitalar', 'posop',
'{{nome}}, parabéns pela cirurgia! 🎉

Agora é focar na recuperação.

O Dr. Luiz indicou retorno em {{dias_retorno}} dias para avaliar a ferida.

Qual local fica melhor para você?
📍 Vitória (quartas)
📍 Vila Velha (quintas)',
ARRAY['nome', 'dias_retorno']),

-- Pós-op
('POSOP_1D', 'Pós-op 1 dia', 'posop',
'Olá, {{nome}}! Como está se sentindo hoje? 🙂

Lembre-se das orientações:
- Repouso
- Medicações no horário

Qualquer dúvida, estou aqui!',
ARRAY['nome']),

('POSOP_3D', 'Pós-op 3 dias', 'posop',
'{{nome}}, já são 3 dias! 💪

Como está a recuperação?
Alguma dúvida ou preocupação?',
ARRAY['nome']),

('POSOP_7D', 'Pós-op 7 dias', 'posop',
'{{nome}}, uma semana de recuperação!

Seu retorno está marcado para {{data_retorno}}.
Tudo certo para comparecer?',
ARRAY['nome', 'data_retorno'])

ON CONFLICT (codigo) DO UPDATE SET
    template = EXCLUDED.template,
    atualizado_em = NOW();

-- ============================================================
-- 11. FUNÇÕES AUXILIARES
-- ============================================================

-- Função para buscar valor da consulta por convênio e local
CREATE OR REPLACE FUNCTION clinica.buscar_valor_consulta(
    p_convenio_codigo VARCHAR,
    p_local_apelido VARCHAR
) RETURNS DECIMAL AS $$
DECLARE
    v_valor DECIMAL;
BEGIN
    SELECT cl.valor_consulta
    INTO v_valor
    FROM clinica.convenios_locais cl
    JOIN clinica.convenios c ON cl.convenio_id = c.id
    JOIN clinica.hospitais h ON cl.local_id = h.id
    WHERE c.codigo = p_convenio_codigo
    AND h.apelido = p_local_apelido
    AND cl.ativo = true;
    
    -- Se não encontrou, retorna valor padrão
    IF v_valor IS NULL THEN
        v_valor := 110.00; -- Padrão para convênios não cadastrados
    END IF;
    
    RETURN v_valor;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar se convênio atende no local
CREATE OR REPLACE FUNCTION clinica.convenio_atende_local(
    p_convenio_codigo VARCHAR,
    p_local_apelido VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM clinica.convenios_locais cl
        JOIN clinica.convenios c ON cl.convenio_id = c.id
        JOIN clinica.hospitais h ON cl.local_id = h.id
        WHERE c.codigo = p_convenio_codigo
        AND h.apelido = p_local_apelido
        AND cl.ativo = true
    );
END;
$$ LANGUAGE plpgsql;

-- Função para buscar locais disponíveis para um convênio
CREATE OR REPLACE FUNCTION clinica.locais_por_convenio(p_convenio_codigo VARCHAR)
RETURNS TABLE (local_nome VARCHAR, local_apelido VARCHAR, valor DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT h.nome::VARCHAR, h.apelido::VARCHAR, cl.valor_consulta
    FROM clinica.convenios_locais cl
    JOIN clinica.convenios c ON cl.convenio_id = c.id
    JOIN clinica.hospitais h ON cl.local_id = h.id
    WHERE c.codigo = p_convenio_codigo
    AND cl.ativo = true;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar template de mensagem
CREATE OR REPLACE FUNCTION clinica.buscar_template(p_codigo VARCHAR)
RETURNS TEXT AS $$
DECLARE
    v_template TEXT;
BEGIN
    SELECT template INTO v_template
    FROM clinica.mensagens_templates
    WHERE codigo = p_codigo AND ativo = true;
    
    RETURN v_template;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 12. VIEW: AGENDA DO DIA COM VALORES
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_agenda_dia_completa AS
SELECT 
    a.id,
    a.tipo,
    a.data_hora,
    a.status,
    a.local_nome,
    a.tipo_consulta,
    a.e_retorno,
    a.valor_previsto,
    a.confirmado_pelo_paciente,
    a.faltou,
    p.id as paciente_id,
    p.nome as paciente_nome,
    p.telefone as paciente_telefone,
    p.status as paciente_status,
    p.etapa as paciente_etapa,
    c.nome as convenio_nome,
    c.codigo as convenio_codigo,
    clinica.dias_desde_consulta(p.id) as dias_desde_consulta,
    h.apelido as local_apelido
FROM clinica.agendamentos a
JOIN clinica.pacientes p ON a.paciente_id = p.id
LEFT JOIN clinica.convenios c ON p.convenio_id = c.id
LEFT JOIN clinica.hospitais h ON a.local_id = h.id
WHERE a.status NOT IN ('cancelado')
ORDER BY a.data_hora;

-- ============================================================
-- 13. VIEW: PENDÊNCIAS PRÉ-OPERATÓRIAS
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_pendencias_preop AS
SELECT 
    pp.id,
    pp.tipo,
    pp.descricao,
    pp.status,
    pp.criado_em,
    pp.resolvido_em,
    p.id as paciente_id,
    p.nome as paciente_nome,
    p.telefone as paciente_telefone,
    c.id as cirurgia_id,
    c.tipo_cirurgia,
    c.data_cirurgia
FROM clinica.pendencias_preop pp
JOIN clinica.pacientes p ON pp.paciente_id = p.id
LEFT JOIN clinica.cirurgias c ON pp.cirurgia_id = c.id
ORDER BY pp.status, pp.criado_em;

-- ============================================================
-- 14. VIEW: CIRURGIAS COM ACOMPANHANTES
-- ============================================================

CREATE OR REPLACE VIEW clinica.vw_cirurgias_completa AS
SELECT 
    c.id,
    c.tipo_cirurgia,
    c.lateralidade,
    c.tecnica,
    c.data_cirurgia,
    c.hora_prevista,
    c.status,
    c.hora_inicio_real,
    c.hora_fim_real,
    c.duracao_minutos_real,
    c.data_alta_hospitalar,
    c.lembrete_3dias_enviado,
    c.lembrete_1dia_enviado,
    c.lembrete_60min_enviado,
    p.id as paciente_id,
    p.nome as paciente_nome,
    p.telefone as paciente_telefone,
    h.nome as hospital_nome,
    h.endereco as hospital_endereco,
    conv.nome as convenio_nome,
    a.nome as acompanhante_nome,
    a.telefone as acompanhante_telefone
FROM clinica.cirurgias c
JOIN clinica.pacientes p ON c.paciente_id = p.id
LEFT JOIN clinica.hospitais h ON c.hospital_id = h.id
LEFT JOIN clinica.convenios conv ON p.convenio_id = conv.id
LEFT JOIN clinica.acompanhantes a ON c.id = a.cirurgia_id
ORDER BY c.data_cirurgia DESC;

-- ============================================================
-- 15. TRIGGER: ATUALIZAR VALOR PREVISTO AO AGENDAR
-- ============================================================

CREATE OR REPLACE FUNCTION clinica.fn_calcular_valor_agendamento()
RETURNS TRIGGER AS $$
DECLARE
    v_convenio_codigo VARCHAR;
    v_local_apelido VARCHAR;
    v_valor DECIMAL;
    v_dias_consulta INT;
BEGIN
    -- Buscar código do convênio do paciente
    SELECT c.codigo INTO v_convenio_codigo
    FROM clinica.pacientes p
    LEFT JOIN clinica.convenios c ON p.convenio_id = c.id
    WHERE p.id = NEW.paciente_id;
    
    -- Buscar apelido do local
    SELECT apelido INTO v_local_apelido
    FROM clinica.hospitais
    WHERE id = NEW.local_id;
    
    -- Verificar se é retorno
    v_dias_consulta := clinica.dias_desde_consulta(NEW.paciente_id);
    
    IF v_dias_consulta < 30 THEN
        NEW.e_retorno := TRUE;
        NEW.tipo_consulta := COALESCE(NEW.tipo_consulta, 'retorno');
        NEW.valor_previsto := 0;
    ELSE
        NEW.e_retorno := FALSE;
        NEW.tipo_consulta := COALESCE(NEW.tipo_consulta, 'primeira');
        NEW.valor_previsto := clinica.buscar_valor_consulta(
            COALESCE(v_convenio_codigo, 'PARTICULAR'),
            COALESCE(v_local_apelido, 'Global Tower')
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger
DROP TRIGGER IF EXISTS trg_calcular_valor ON clinica.agendamentos;
CREATE TRIGGER trg_calcular_valor
    BEFORE INSERT OR UPDATE ON clinica.agendamentos
    FOR EACH ROW
    EXECUTE FUNCTION clinica.fn_calcular_valor_agendamento();

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================

-- Verificação final
DO $$
BEGIN
    RAISE NOTICE 'Script executado com sucesso!';
    RAISE NOTICE 'Tabelas criadas/atualizadas:';
    RAISE NOTICE '  - clinica.convenios_locais';
    RAISE NOTICE '  - clinica.pendencias_preop';
    RAISE NOTICE '  - clinica.acompanhantes';
    RAISE NOTICE '  - clinica.mensagens_templates';
    RAISE NOTICE 'Funções criadas:';
    RAISE NOTICE '  - clinica.buscar_valor_consulta()';
    RAISE NOTICE '  - clinica.convenio_atende_local()';
    RAISE NOTICE '  - clinica.locais_por_convenio()';
    RAISE NOTICE '  - clinica.dias_desde_consulta()';
    RAISE NOTICE '  - clinica.e_retorno()';
END $$;
