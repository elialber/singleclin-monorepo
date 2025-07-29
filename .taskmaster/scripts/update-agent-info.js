#!/usr/bin/env node

/**
 * Script para adicionar informações de agentes delegados nas tarefas
 * Este script lê o mapeamento de agentes e atualiza os arquivos de tarefas
 */

const fs = require('fs');
const path = require('path');

// Mapeamento de agentes por tarefa
const agentMapping = {
  1: { agent: 'monorepo-architect', description: 'Especialista em monorepo e build systems' },
  2: { agent: 'dotnet-api-expert', description: 'Especialista em .NET backend e APIs' },
  3: { agent: 'database-architect', description: 'Especialista em PostgreSQL e Entity Framework' },
  4: { agent: 'auth-security-expert', auxiliary: 'dotnet-api-expert', description: 'Especialista em autenticação e segurança' },
  5: { agent: 'dotnet-api-expert', auxiliary: 'database-architect', description: 'Especialista em CRUD e APIs REST' },
  6: { agent: 'flutter-mobile-expert', description: 'Especialista em Flutter e desenvolvimento mobile' },
  7: { agent: 'flutter-mobile-expert', auxiliary: 'auth-security-expert', description: 'Especialista em autenticação mobile' },
  8: { agent: 'qr-transaction-specialist', description: 'Especialista em QR codes e transações' },
  9: { agent: 'flutter-mobile-expert', description: 'Especialista em UI/UX mobile' },
  10: { agent: 'flutter-mobile-expert', auxiliary: 'qr-transaction-specialist', description: 'Especialista em QR code display' },
  11: { agent: 'qr-transaction-specialist', auxiliary: 'dotnet-api-expert', description: 'Especialista em validação de QR codes' },
  12: { agent: 'flutter-mobile-expert', auxiliary: 'qr-transaction-specialist', description: 'Especialista em scanner mobile' },
  13: { agent: 'react-admin-specialist', description: 'Especialista em React e dashboards' },
  14: { agent: 'notification-system-expert', description: 'Especialista em notificações e comunicação' },
  15: { agent: 'analytics-reporting-specialist', description: 'Especialista em analytics e relatórios' }
};

// Função para adicionar informação de agente no arquivo de tarefa
function updateTaskFile(taskId) {
  const taskFile = path.join(__dirname, '..', 'tasks', `task_${String(taskId).padStart(3, '0')}.txt`);
  
  if (!fs.existsSync(taskFile)) {
    console.log(`Arquivo não encontrado: ${taskFile}`);
    return;
  }

  let content = fs.readFileSync(taskFile, 'utf8');
  const mapping = agentMapping[taskId];
  
  if (!mapping) {
    console.log(`Mapeamento não encontrado para tarefa ${taskId}`);
    return;
  }

  // Adicionar seção de agente delegado se ainda não existir
  if (!content.includes('# Agente Delegado:')) {
    let agentSection = `\n# Agente Delegado:\n**Principal:** @${mapping.agent}\n${mapping.description}`;
    
    if (mapping.auxiliary) {
      agentSection += `\n**Auxiliar:** @${mapping.auxiliary}`;
    }
    
    // Inserir após a seção de Test Strategy
    const testStrategyIndex = content.indexOf('# Test Strategy:');
    if (testStrategyIndex !== -1) {
      const nextSectionIndex = content.indexOf('\n#', testStrategyIndex + 1);
      const insertIndex = nextSectionIndex !== -1 ? nextSectionIndex : content.length;
      content = content.slice(0, insertIndex) + agentSection + '\n' + content.slice(insertIndex);
    } else {
      content += agentSection;
    }
    
    fs.writeFileSync(taskFile, content);
    console.log(`✅ Atualizada tarefa ${taskId} com agente ${mapping.agent}`);
  } else {
    console.log(`ℹ️  Tarefa ${taskId} já possui informação de agente`);
  }
}

// Processar todas as tarefas
console.log('🚀 Iniciando atualização de agentes nas tarefas...\n');

for (let taskId = 1; taskId <= 15; taskId++) {
  updateTaskFile(taskId);
}

console.log('\n✨ Atualização concluída!');
console.log('📝 Consulte .taskmaster/docs/agent-mapping.md para referência completa');