-- ============================================================
-- MAX - DADOS INICIAIS (SEED)
-- Consultório Dr. Luiz Segundo
-- ============================================================

-- Este arquivo é executado após as migrações
-- Contém dados iniciais necessários para o sistema funcionar

-- ============================================================
-- 1. USUÁRIOS DA EQUIPE
-- ============================================================
INSERT INTO clinica.usuarios (nome, email, telefone, perfil, ativo) VALUES
('Dr. Luiz Segundo', 'contato@drluizsegundo.com.br', '5527999530202', 'admin', true),
('Dany', 'dany@drluizsegundo.com.br', '5527997042195', 'assistente', true),
('Dra. Lara', 'lara@drluizsegundo.com.br', '5528999191863', 'cirurgiao_auxiliar', true)
ON CONFLICT (email) DO UPDATE SET 
    telefone = EXCLUDED.telefone,
    perfil = EXCLUDED.perfil,
    ativo = EXCLUDED.ativo;

-- ============================================================
-- 2. LINK DO GOOGLE REVIEWS
-- ============================================================
INSERT INTO clinica.configuracoes (chave, valor, descricao) VALUES
('link_google_reviews', '"https://g.page/r/drluizsegundo/review"', 'Link para avaliações no Google')
ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor;

-- ============================================================
-- 3. TELEFONES CONHECIDOS (para identificação de perfil)
-- ============================================================
-- Nota: Esta tabela fica no schema public para o workflow n8n
INSERT INTO public.telefones_conhecidos (telefone, nome, perfil, organizacao) VALUES
('5527999530202', 'Dr. Luiz Segundo', 'equipe_luiz', 'Consultório'),
('5527997042195', 'Dany', 'equipe_dany', 'Consultório'),
('5528999191863', 'Dra. Lara', 'equipe_lara', 'Consultório')
ON CONFLICT (telefone) DO UPDATE SET 
    nome = EXCLUDED.nome,
    perfil = EXCLUDED.perfil;

-- ============================================================
-- FIM DO SEED
-- ============================================================
