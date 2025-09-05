# 🏥 SingleClin - Clinic Registration Stepper

Uma implementação completa de um stepper multi-etapas para cadastro de clínicas no sistema SingleClin, com UX otimizada, validações robustas e integrações com serviços externos.

## 🎯 Funcionalidades Implementadas

### ✅ Fase 1: Infraestrutura Base
- Context API para gerenciamento de estado global
- Navegação entre steps com validação
- Componente base `<ClinicStepper />` com indicador visual
- Hooks customizados para diferentes aspectos do stepper

### ✅ Fase 2: Step 1 - Informações Básicas
- Formulário com validação em tempo real
- Máscaras para CNPJ e telefone brasileiros
- Validação CNPJ com algoritmo de dígitos verificadores
- Auto-complete para nomes de clínicas
- Verificação de duplicatas (mock)
- Tooltips explicativos e feedback visual

### ✅ Fase 3: Step 2 - Endereço e Localização
- Integração com ViaCEP API para busca automática por CEP
- Google Maps com marcador arrastável
- Geocoding e reverse geocoding
- Obtenção de localização atual via GPS
- Validação cruzada de endereço e coordenadas
- Sincronização bidirecional formulário ↔ mapa

### ✅ Fase 4: Step 3 - Upload Múltiplo de Imagens
- Drag & drop de múltiplas imagens com react-dropzone
- Validação completa: tipos, tamanhos, dimensões, magic bytes
- Grid responsivo de thumbnails com preview
- Upload simultâneo com progress bars individuais
- Sistema de retry automático para falhas
- Definição de imagem principal (featured)
- Edição de alt text para acessibilidade
- Batch operations: seleção e ações múltiplas
- Modal de preview com zoom
- Reordenação por drag & drop

## 🏗️ Estrutura de Arquivos

```
src/components/clinic/stepper/
├── core/
│   ├── ClinicStepper.tsx          # Componente principal do stepper
│   ├── StepperProvider.tsx        # Context provider com estado global
│   ├── StepperIndicator.tsx       # Indicador visual de progresso
│   ├── StepperNavigation.tsx      # Navegação entre steps
│   ├── DraftModal.tsx             # Modal para gerenciar rascunhos
│   ├── DraftIndicator.tsx         # Indicador de status de draft
│   ├── ResponsiveStepperLayout.tsx # Layout responsivo
│   └── StepperAnimations.tsx      # Componente de animações
├── steps/
│   ├── Step1BasicInfo.tsx         # Informações básicas da clínica
│   ├── Step2AddressLocation.tsx   # Endereço e localização
│   ├── Step3ImageUpload.tsx       # Upload múltiplo de imagens
│   └── Step4Review.tsx            # Revisão final e submissão
├── hooks/
│   ├── useClinicStepper.ts        # Hook principal do stepper
│   ├── useInputValidation.ts      # Hooks para validação de inputs
│   ├── useImageUpload.ts          # Hook para upload de imagens
│   ├── useDraftSaver.ts           # Hook para sistema de rascunhos
│   ├── useAccessibility.ts        # Hook para recursos de acessibilidade
│   └── usePerformanceOptimizations.ts # Hook para otimizações de performance
├── examples/
│   ├── Step1Example.tsx           # Exemplo de uso Step 1
│   ├── Step2Example.tsx           # Exemplo de uso Step 2
│   ├── Step3Example.tsx           # Exemplo de uso Step 3
│   └── Step4Example.tsx           # Exemplo de uso Step 4
├── __tests__/                     # Testes do stepper
│   ├── validation.test.ts         # Testes de validação
│   ├── useDraftSaver.test.ts      # Testes do hook de draft
│   ├── ClinicStepper.test.tsx     # Testes do componente principal
│   ├── performance.test.ts        # Testes de performance
│   └── e2e/                       # Testes end-to-end
│       └── stepper-flow.spec.ts   # Fluxo completo E2E
└── README.md                      # Este arquivo

src/services/
└── draftService.ts                # Serviço de gerenciamento de rascunhos

src/utils/
├── validation.ts                  # Utilitários de validação
├── maps.ts                        # Utilitários Google Maps
├── imageValidation.ts             # Validação e processamento de imagens
└── uploadService.ts               # Serviço de upload múltiplo

src/types/
└── stepper.ts                     # Interfaces TypeScript

src/styles/
└── react-grid-layout.css         # Estilos para grid de imagens

src/test/
└── setup.ts                      # Configuração dos testes

# Arquivos de configuração
├── vitest.config.ts               # Configuração Vitest
├── playwright.config.ts           # Configuração Playwright
└── package.json                   # Dependências de teste
```

## 🚀 Como Usar

### Uso Básico

```tsx
import { ClinicStepper } from '@/components/clinic/stepper/core/ClinicStepper'
import { ClinicFormData } from '@/types/stepper'

function MyClinicForm() {
  const handleSubmit = async (data: ClinicFormData) => {
    // Processar dados do formulário
    console.log('Clínica cadastrada:', data)
  }

  return (
    <ClinicStepper
      onSubmit={handleSubmit}
      title="Cadastro de Nova Clínica"
    />
  )
}
```

### Modo Edição (com dados pré-preenchidos)

```tsx
const initialData = {
  basicInfo: {
    name: 'Clínica São Paulo',
    type: ClinicType.Regular,
    cnpj: '11.222.333/0001-81',
    // ... outros dados
  },
  address: {
    cep: '01310-100',
    street: 'Avenida Paulista',
    // ... outros dados
  }
}

<ClinicStepper
  initialData={initialData}
  onSubmit={handleUpdate}
  title="Editar Clínica"
/>
```

## 🔧 Configuração Necessária

### Variáveis de Ambiente

**🚨 OBRIGATÓRIO**: Configure a Google Maps API antes de usar o Step 2 (Endereço).

Crie um arquivo `.env.local`:

```bash
# Google Maps API (obrigatório para Step 2)
VITE_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**📋 COMO OBTER A CHAVE:**
1. **Consulte o guia completo** no arquivo `PLANO-WIZARD-CADASTRO-CLINICA.md`
2. **Seção**: "🗝️ CONFIGURAÇÃO GOOGLE MAPS API"
3. **Passo a passo detalhado** com prints e troubleshooting
4. **Estimativa de custo**: $0.00/mês para uso normal

**APIs necessárias no Google Console:**
- ✅ **Maps JavaScript API** (exibir mapa)
- ✅ **Geocoding API** (coordenadas ↔ endereço)  
- ✅ **Places API** (futuro - autocompletar)

### Dependências

As seguintes dependências foram adicionadas:

```json
{
  "dependencies": {
    "@types/google.maps": "^3.58.1"
  }
}
```

## 📋 APIs e Serviços Utilizados

### ViaCEP API
- **URL**: `https://viacep.com.br/ws/{cep}/json/`
- **Uso**: Auto-preenchimento de endereço por CEP
- **Gratuito**: Sem necessidade de API key

### Google Maps API
- **Serviços utilizados**:
  - Maps JavaScript API (exibição do mapa)
  - Geocoding API (conversão endereço → coordenadas)
  - Reverse Geocoding (coordenadas → endereço)
- **Configuração**: Necessária API key válida

### Browser Geolocation API
- **Uso**: Obtenção da localização atual do usuário
- **Permissão**: Solicitada automaticamente pelo navegador

## 🎨 Componentes UI

### Step 1: Informações Básicas
- **Campos**: Nome, Tipo, CNPJ, Telefone, Email, Status Ativo
- **Validações**: Tempo real com debounce para verificação de duplicatas
- **Máscaras**: CNPJ (XX.XXX.XXX/XXXX-XX), Telefone ((XX) XXXXX-XXXX)
- **UX**: Auto-complete, tooltips, indicadores visuais de validação

### Step 2: Endereço e Localização
- **Layout**: Split screen (formulário + mapa)
- **Campos**: CEP, Endereço, Número, Complemento, Bairro, Cidade, Estado
- **Mapa**: Google Maps com marcador arrastável
- **Integrações**: ViaCEP, Geocoding, GPS
- **UX**: Preenchimento automático, sincronização bidirecional

## 🔍 Validações Implementadas

### CNPJ
- Formato brasileiro (XX.XXX.XXX/XXXX-XX)
- Algoritmo completo de dígitos verificadores
- Verificação de CNPJs conhecidos como inválidos
- Verificação de duplicatas (mock)

### Telefone
- Suporte a fixo (10 dígitos) e celular (11 dígitos)
- Validação de 75 DDDs brasileiros válidos
- Para celular: 3º dígito deve ser 9

### CEP
- Formato brasileiro (XXXXX-XXX)
- Integração com ViaCEP para validação
- Auto-preenchimento de endereço

### Coordenadas Geográficas
- Validação de limites (latitude: -90 a 90, longitude: -180 a 180)
- Verificação se está dentro dos limites do Brasil (opcional)

## 🧪 Testes e Exemplos

### Componentes de Exemplo
- `Step1Example.tsx`: Demonstra todas as funcionalidades do Step 1
- `Step2Example.tsx`: Demonstra integração com mapas e geolocalização

### Casos de Teste
Execute os exemplos para testar:
1. Validação de campos obrigatórios
2. Máscaras de input funcionando
3. Verificação de duplicatas
4. Auto-preenchimento por CEP
5. Funcionalidades do mapa (arrastar, clicar, GPS)

## 🎯 Próximos Passos

### ✅ Fase 4: Step 3 - Upload Múltiplo de Imagens
- Drag & drop de múltiplas imagens com react-dropzone
- Validação completa: tipos, tamanhos, dimensões, magic bytes
- Grid responsivo de thumbnails com preview
- Upload simultâneo com progress bars individuais
- Sistema de retry automático para falhas
- Definição de imagem principal (featured)
- Edição de alt text para acessibilidade
- Batch operations: seleção e ações múltiplas
- Modal de preview com zoom
- Reordenação por drag & drop

### ✅ Fase 5: Step 4 - Revisão Final
- Resumo visual completo de todos os dados
- Edição inline de campos principais
- Navegação para steps específicos para correções
- Seções expandíveis/recolhíveis
- Validação final cross-etapas
- Estados visuais de progresso por step
- Preview de imagens com informações detalhadas
- Indicadores de campos obrigatórios

### ✅ Fase 6: Sistema Draft/Rascunhos
- Auto-save automático a cada 30 segundos
- Salvamento manual com títulos customizados
- Modal de gerenciamento de rascunhos
- Recuperação automática na inicialização
- Indicador visual de status de salvamento
- Export/Import de rascunhos
- Limpeza automática de rascunhos antigos (30+ dias)

### ✅ Fase 7: Polish e Responsividade
- Design totalmente responsivo (mobile-first)
- Layout adaptativo para tablet e desktop
- Micro-animações suaves entre steps
- Suporte completo a navegação por teclado
- Screen reader support (ARIA labels)
- Modo alto contraste automático
- Otimizações de performance com lazy loading
- Hooks de otimização com throttling/debouncing

### ✅ Fase 8: Testes Completos
- Testes unitários (Vitest + Testing Library)
- Testes de integração para todos os hooks
- Testes E2E com Playwright
- Testes de performance e acessibilidade
- Coverage de 80%+ em todas as métricas
- Configuração completa de CI/CD

## 🐛 Troubleshooting

### Google Maps não carrega
1. Verificar se `VITE_GOOGLE_MAPS_API_KEY` está configurada
2. Confirmar que as APIs necessárias estão habilitadas no Google Console
3. Verificar cotas e billing no Google Cloud Platform

### ViaCEP não funciona
- ViaCEP é um serviço gratuito e pode ter limitações de rate limit
- Em caso de falha, os campos podem ser preenchidos manualmente

### Geolocalização não funciona
- Funciona apenas em HTTPS (exceto localhost)
- Usuário deve conceder permissão no navegador
- Fallback: usar coordenadas do centro do Brasil

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

---

**Status do Projeto**: 77/83 tasks completas (93% - Fases 1-8 completas - Frontend FINALIZADO! ✅)**