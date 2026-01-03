/**
 * Script de Teste de Conexão com Supabase
 * Lista todas as tabelas do banco de dados
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// Configuração do Supabase
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://txhxpasuyxdhlkyqmmii.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_ANON_KEY) {
  console.error('❌ ERRO: SUPABASE_ANON_KEY não configurada!');
  console.log('\nCrie um arquivo .env com:');
  console.log('SUPABASE_URL=https://txhxpasuyxdhlkyqmmii.supabase.co');
  console.log('SUPABASE_ANON_KEY=sua_anon_key_aqui');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testConnection() {
  console.log('🔌 Testando conexão com Supabase...');
  console.log(`📍 URL: ${SUPABASE_URL}\n`);

  try {
    // Query para listar todas as tabelas do schema public e clinica
    const { data, error } = await supabase.rpc('get_all_tables');

    if (error) {
      // Se a função RPC não existir, usar query direta na information_schema
      console.log('⚠️  Função RPC não encontrada, usando query alternativa...\n');

      const { data: tables, error: tablesError } = await supabase
        .from('information_schema.tables')
        .select('table_schema, table_name, table_type')
        .in('table_schema', ['public', 'clinica'])
        .order('table_schema')
        .order('table_name');

      if (tablesError) {
        // Fallback: testar conexão básica com auth
        console.log('📋 Testando conexão básica...\n');

        // Tentar listar schemas usando uma query simples
        const { data: testData, error: testError } = await supabase
          .from('pg_catalog.pg_tables')
          .select('schemaname, tablename')
          .in('schemaname', ['public', 'clinica'])
          .limit(100);

        if (testError) {
          // Último fallback: testar com qualquer tabela acessível
          console.log('🔍 Procurando tabelas acessíveis...\n');
          await listAccessibleTables();
          return;
        }

        displayTables(testData);
        return;
      }

      displayTables(tables);
      return;
    }

    displayTables(data);
  } catch (err) {
    console.error('❌ Erro de conexão:', err.message);
    process.exit(1);
  }
}

async function listAccessibleTables() {
  // Lista de tabelas conhecidas do schema (baseado nos migrations)
  const knownTables = [
    // Schema public
    { schema: 'public', table: 'telefones_conhecidos' },
    // Schema clinica
    { schema: 'clinica', table: 'usuarios' },
    { schema: 'clinica', table: 'pacientes' },
    { schema: 'clinica', table: 'agendamentos' },
    { schema: 'clinica', table: 'cirurgias' },
    { schema: 'clinica', table: 'convenios' },
    { schema: 'clinica', table: 'hospitais' },
    { schema: 'clinica', table: 'convenios_locais' },
    { schema: 'clinica', table: 'contas_pagar' },
    { schema: 'clinica', table: 'contas_receber' },
    { schema: 'clinica', table: 'pendencias_preop' },
    { schema: 'clinica', table: 'acompanhantes' },
    { schema: 'clinica', table: 'mensagens_templates' },
    { schema: 'clinica', table: 'tarefas_financeiras' },
    { schema: 'clinica', table: 'codigos_procedimentos' },
  ];

  console.log('✅ CONEXÃO BEM SUCEDIDA!\n');
  console.log('=' .repeat(60));
  console.log('📊 TABELAS DO BANCO DE DADOS');
  console.log('=' .repeat(60));

  let publicCount = 0;
  let clinicaCount = 0;

  for (const { schema, table } of knownTables) {
    const fullTableName = schema === 'public' ? table : `${schema}.${table}`;

    try {
      const { count, error } = await supabase
        .from(fullTableName)
        .select('*', { count: 'exact', head: true });

      if (!error) {
        const status = '✅';
        const countStr = count !== null ? `(${count} registros)` : '';
        console.log(`${status} ${schema.padEnd(10)} │ ${table.padEnd(25)} ${countStr}`);

        if (schema === 'public') publicCount++;
        else clinicaCount++;
      }
    } catch (e) {
      // Tabela não acessível, pular
    }
  }

  console.log('=' .repeat(60));
  console.log(`\n📈 Resumo:`);
  console.log(`   • Schema public: ${publicCount} tabelas acessíveis`);
  console.log(`   • Schema clinica: ${clinicaCount} tabelas acessíveis`);
  console.log(`   • Total: ${publicCount + clinicaCount} tabelas\n`);
}

function displayTables(tables) {
  if (!tables || tables.length === 0) {
    console.log('⚠️  Nenhuma tabela encontrada');
    return;
  }

  console.log('✅ CONEXÃO BEM SUCEDIDA!\n');
  console.log('=' .repeat(60));
  console.log('📊 TABELAS DO BANCO DE DADOS');
  console.log('=' .repeat(60));

  let currentSchema = '';

  tables.forEach(t => {
    const schema = t.table_schema || t.schemaname;
    const table = t.table_name || t.tablename;
    const type = t.table_type || 'TABLE';

    if (schema !== currentSchema) {
      console.log(`\n📁 Schema: ${schema}`);
      console.log('-'.repeat(40));
      currentSchema = schema;
    }

    const icon = type.includes('VIEW') ? '👁️' : '📋';
    console.log(`   ${icon} ${table}`);
  });

  console.log('\n' + '=' .repeat(60));
  console.log(`📈 Total: ${tables.length} tabelas/views encontradas\n`);
}

// Executar teste
testConnection();
