# SingleClin - Casos de Uso e Caderno de Testes

## Sumário
1. [Visão Geral do Sistema](#visão-geral-do-sistema)
2. [Casos de Uso](#casos-de-uso)
   - [Web Admin](#casos-de-uso---web-admin)
   - [Backend API](#casos-de-uso---backend-api)
   - [Mobile App](#casos-de-uso---mobile-app)
3. [Caderno de Testes](#caderno-de-testes)
   - [Testes Unitários](#testes-unitários)
   - [Testes de Integração](#testes-de-integração)
   - [Testes E2E](#testes-e2e)
   - [Testes de Sistema Integrado](#testes-de-sistema-integrado)
4. [Cenários de Teste Críticos](#cenários-de-teste-críticos)
5. [Matriz de Rastreabilidade](#matriz-de-rastreabilidade)

---

## Visão Geral do Sistema

O SingleClin é um sistema de gestão de saúde baseado em créditos que permite:
- Pacientes compram planos de tratamento em uma clínica principal
- Utilizam créditos em qualquer clínica parceira da rede
- Gestão completa através de portal web administrativo
- Aplicativo móvel para pacientes e clínicas

### Arquitetura
- **Frontend Web Admin**: React + TypeScript + Material-UI
- **Backend API**: .NET 9 + PostgreSQL + Redis + Firebase
- **Mobile App**: Flutter + GetX + Firebase Auth

---

## Casos de Uso

### Casos de Uso - Web Admin

#### UC001: Autenticação de Administrador
**Ator**: Administrador do Sistema
**Pré-condições**: Usuário cadastrado com perfil de administrador
**Fluxo Principal**:
1. Administrador acessa a página de login
2. Informa email e senha
3. Sistema valida credenciais no Firebase
4. Sistema autentica no backend com token Firebase
5. Sistema redireciona para dashboard

**Fluxo Alternativo - Login com Google**:
1. Administrador clica em "Entrar com Google"
2. Sistema abre popup de autenticação Google
3. Usuário autoriza acesso
4. Sistema processa token e autentica

**Pós-condições**: Usuário autenticado com acesso ao dashboard

#### UC002: Gestão de Clínicas
**Ator**: Administrador
**Pré-condições**: Autenticado no sistema
**Fluxo Principal**:
1. Administrador acessa menu "Clínicas"
2. Sistema exibe lista de clínicas cadastradas
3. Administrador pode:
   - Visualizar detalhes de clínica
   - Adicionar nova clínica
   - Editar informações
   - Ativar/desativar clínica
   - Definir tipo (Origin/Partner)

#### UC003: Gestão de Planos
**Ator**: Administrador
**Pré-condições**: Autenticado no sistema
**Fluxo Principal**:
1. Administrador acessa menu "Planos"
2. Sistema exibe lista de planos
3. Administrador pode:
   - Criar novo plano
   - Definir nome, créditos e preço
   - Editar plano existente
   - Ativar/desativar plano

#### UC004: Visualização de Dashboard
**Ator**: Administrador
**Pré-condições**: Autenticado no sistema
**Fluxo Principal**:
1. Sistema exibe métricas principais:
   - Total de pacientes
   - Total de transações
   - Receita total
   - Planos ativos
2. Sistema exibe gráficos:
   - Transações por dia
   - Distribuição por plano
   - Top 10 clínicas

#### UC005: Gestão de Transações
**Ator**: Administrador
**Pré-condições**: Autenticado no sistema
**Fluxo Principal**:
1. Administrador acessa menu "Transações"
2. Sistema exibe lista de transações
3. Administrador pode:
   - Filtrar por período
   - Filtrar por clínica
   - Filtrar por paciente
   - Exportar relatório

#### UC006: Relatórios Gerenciais
**Ator**: Administrador
**Pré-condições**: Autenticado no sistema
**Fluxo Principal**:
1. Administrador acessa menu "Relatórios"
2. Seleciona tipo de relatório:
   - Utilização de planos
   - Ranking de clínicas
   - Análise de serviços
3. Define período e filtros
4. Sistema gera relatório
5. Administrador pode exportar (PDF/Excel)

### Casos de Uso - Backend API

#### UC007: Autenticação via Firebase
**Ator**: Sistema Frontend (Web/Mobile)
**Pré-condições**: Token Firebase válido
**Fluxo Principal**:
1. Frontend envia token Firebase
2. Backend valida token com Firebase Admin SDK
3. Backend busca/cria usuário no banco local
4. Backend gera JWT interno
5. Backend retorna tokens de acesso e refresh

#### UC008: Validação de QR Code
**Ator**: Aplicativo da Clínica
**Pré-condições**: QR Code válido gerado
**Fluxo Principal**:
1. Clínica escaneia QR Code
2. Backend valida:
   - Token JWT no QR Code
   - Tempo de expiração (30 min)
   - Nonce único no Redis
3. Backend registra transação
4. Backend debita créditos do plano
5. Backend retorna confirmação

#### UC009: Geração de QR Code
**Ator**: Aplicativo do Paciente
**Pré-condições**: Paciente com plano ativo
**Fluxo Principal**:
1. Paciente solicita QR Code
2. Backend verifica saldo de créditos
3. Backend gera JWT temporário
4. Backend armazena nonce no Redis
5. Backend retorna QR Code

#### UC010: Gestão de Créditos
**Ator**: Sistema
**Pré-condições**: Transação validada
**Fluxo Principal**:
1. Sistema identifica plano do paciente
2. Sistema verifica saldo disponível
3. Sistema debita créditos
4. Sistema atualiza saldo
5. Sistema notifica paciente se saldo baixo

### Casos de Uso - Mobile App

#### UC011: Login de Paciente
**Ator**: Paciente
**Pré-condições**: App instalado
**Fluxo Principal**:
1. Paciente abre o app
2. Informa email e senha
3. App autentica via Firebase
4. App obtém token do backend
5. App exibe tela inicial

**Fluxo Alternativo - Biometria**:
1. App verifica biometria disponível
2. Paciente autoriza com biometria
3. App recupera credenciais salvas
4. App realiza login automático

#### UC012: Visualização de Planos
**Ator**: Paciente
**Pré-condições**: Autenticado no app
**Fluxo Principal**:
1. Paciente acessa "Meus Planos"
2. App exibe planos ativos
3. Para cada plano, mostra:
   - Nome do plano
   - Créditos restantes
   - Data de validade
   - Histórico de uso

#### UC013: Geração de QR Code para Atendimento
**Ator**: Paciente
**Pré-condições**: Plano ativo com créditos
**Fluxo Principal**:
1. Paciente seleciona plano
2. Toca em "Gerar QR Code"
3. App solicita ao backend
4. App exibe QR Code
5. QR Code expira em 30 minutos

#### UC014: Scanner de QR Code (Clínica)
**Ator**: Funcionário da Clínica
**Pré-condições**: Login com perfil de clínica
**Fluxo Principal**:
1. Funcionário acessa scanner
2. Aponta câmera para QR Code
3. App lê e valida QR Code
4. App exibe dados do paciente
5. Funcionário confirma atendimento
6. App registra transação

#### UC015: Histórico de Atendimentos
**Ator**: Paciente/Clínica
**Pré-condições**: Autenticado
**Fluxo Principal**:
1. Usuário acessa "Histórico"
2. App exibe lista de atendimentos
3. Para cada atendimento:
   - Data e hora
   - Clínica
   - Serviço realizado
   - Créditos utilizados

---

## Caderno de Testes

### Testes Unitários

#### Backend (.NET)

**TU001: AuthService - Validação de Token Firebase**
```csharp
[Test]
public async Task ValidateFirebaseToken_ValidToken_ReturnsUser()
{
    // Arrange
    var mockToken = "valid.firebase.token";
    var expectedUid = "firebase123";
    
    // Act
    var result = await _authService.ValidateFirebaseTokenAsync(mockToken);
    
    // Assert
    Assert.IsNotNull(result);
    Assert.AreEqual(expectedUid, result.FirebaseUid);
}
```

**TU002: QRCodeService - Geração de Token**
```csharp
[Test]
public void GenerateQRToken_ValidUser_ReturnsValidJWT()
{
    // Arrange
    var userId = "user123";
    var planId = "plan456";
    
    // Act
    var token = _qrCodeService.GenerateToken(userId, planId);
    
    // Assert
    Assert.IsNotNull(token);
    Assert.IsTrue(token.Length > 0);
    // Validate JWT structure
}
```

**TU003: PlanService - Débito de Créditos**
```csharp
[Test]
public async Task DebitCredits_SufficientBalance_Success()
{
    // Arrange
    var userPlanId = "userplan123";
    var creditsToDebit = 5;
    var initialBalance = 10;
    
    // Act
    var result = await _planService.DebitCreditsAsync(userPlanId, creditsToDebit);
    
    // Assert
    Assert.IsTrue(result.Success);
    Assert.AreEqual(initialBalance - creditsToDebit, result.RemainingCredits);
}
```

#### Frontend (React)

**TU004: AuthService - Login com Email**
```typescript
describe('AuthService', () => {
  it('deve fazer login com email e senha', async () => {
    // Arrange
    const email = 'test@example.com';
    const password = 'Test123@';
    
    // Act
    const result = await authService.login(email, password);
    
    // Assert
    expect(result).toBeDefined();
    expect(result.accessToken).toBeTruthy();
    expect(result.user.email).toBe(email);
  });
});
```

**TU005: Dashboard - Formatação de Valores**
```typescript
describe('Dashboard Utils', () => {
  it('deve formatar valores monetários corretamente', () => {
    // Arrange
    const value = 1234.56;
    
    // Act
    const formatted = formatCurrency(value);
    
    // Assert
    expect(formatted).toBe('R$ 1.234,56');
  });
});
```

#### Mobile (Flutter)

**TU006: AuthController - Validação de Login**
```dart
test('deve validar credenciais de login', () async {
  // Arrange
  final controller = AuthController();
  const email = 'test@example.com';
  const password = 'Test123@';
  
  // Act
  final result = await controller.login(email, password);
  
  // Assert
  expect(result, isTrue);
  expect(controller.user.value, isNotNull);
  expect(controller.user.value!.email, equals(email));
});
```

### Testes de Integração

#### TI001: Fluxo de Autenticação Completo
**Objetivo**: Validar integração Firebase + Backend + Frontend
```javascript
describe('Fluxo de Autenticação', () => {
  it('deve autenticar usuário do Firebase ao Dashboard', async () => {
    // 1. Login no Firebase
    const firebaseUser = await signInWithEmail('test@example.com', 'Test123@');
    
    // 2. Obter token Firebase
    const idToken = await firebaseUser.getIdToken();
    
    // 3. Autenticar no backend
    const response = await api.post('/auth/login/firebase', {
      firebaseToken: idToken
    });
    
    // 4. Validar resposta
    expect(response.status).toBe(200);
    expect(response.data.accessToken).toBeDefined();
    expect(response.data.user).toBeDefined();
  });
});
```

#### TI002: Fluxo de QR Code
**Objetivo**: Validar geração e validação de QR Code
```csharp
[Test]
public async Task QRCodeFlow_GenerateAndValidate_Success()
{
    // 1. Gerar QR Code
    var generateRequest = new QRCodeGenerateRequest 
    { 
        UserId = "user123",
        PlanId = "plan456" 
    };
    var qrCode = await _qrCodeService.GenerateAsync(generateRequest);
    
    // 2. Validar QR Code
    var validateRequest = new QRCodeValidateRequest 
    { 
        Token = qrCode.Token 
    };
    var validation = await _qrCodeService.ValidateAsync(validateRequest);
    
    // 3. Verificar transação criada
    Assert.IsTrue(validation.Success);
    Assert.IsNotNull(validation.TransactionId);
}
```

### Testes E2E

#### TE001: Jornada Completa do Administrador
```javascript
describe('E2E - Admin Journey', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('deve completar jornada de gestão de planos', () => {
    // Login
    cy.get('[data-testid="email-input"]').type('admin@singleclin.com');
    cy.get('[data-testid="password-input"]').type('Admin123@');
    cy.get('[data-testid="login-button"]').click();
    
    // Aguardar dashboard
    cy.url().should('include', '/dashboard');
    
    // Navegar para planos
    cy.get('[data-testid="menu-plans"]').click();
    
    // Criar novo plano
    cy.get('[data-testid="add-plan-button"]').click();
    cy.get('[data-testid="plan-name"]').type('Plano Teste E2E');
    cy.get('[data-testid="plan-credits"]').type('50');
    cy.get('[data-testid="plan-price"]').type('299.90');
    cy.get('[data-testid="save-plan-button"]').click();
    
    // Verificar plano criado
    cy.contains('Plano Teste E2E').should('exist');
  });
});
```

#### TE002: Jornada do Paciente - Mobile
```dart
testWidgets('Jornada completa do paciente', (WidgetTester tester) async {
  // Login
  await tester.pumpWidget(MyApp());
  await tester.enterText(find.byKey(Key('email_field')), 'patient@test.com');
  await tester.enterText(find.byKey(Key('password_field')), 'Test123@');
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();
  
  // Verificar tela inicial
  expect(find.text('Meus Planos'), findsOneWidget);
  
  // Gerar QR Code
  await tester.tap(find.byKey(Key('generate_qr_button')));
  await tester.pumpAndSettle();
  
  // Verificar QR Code exibido
  expect(find.byType(QrImage), findsOneWidget);
});
```

### Testes de Sistema Integrado

#### TSI001: Fluxo Completo de Atendimento
**Cenário**: Paciente usa créditos em clínica parceira
**Atores**: Paciente (Mobile), Clínica (Mobile), Admin (Web)

```gherkin
Feature: Atendimento com Créditos
  Como paciente
  Quero usar meus créditos em qualquer clínica parceira
  Para receber atendimento médico

  Background:
    Given existe um paciente "João Silva" com email "joao@test.com"
    And existe uma clínica parceira "Clínica Norte"
    And o paciente possui o "Plano Gold" com 20 créditos

  Scenario: Atendimento bem-sucedido
    # Paciente gera QR Code
    Given o paciente está logado no app mobile
    When o paciente acessa "Meus Planos"
    And seleciona o "Plano Gold"
    And toca em "Gerar QR Code"
    Then um QR Code é exibido na tela
    And o QR Code tem validade de 30 minutos

    # Clínica valida QR Code
    Given o funcionário da clínica está logado
    When o funcionário acessa o scanner
    And escaneia o QR Code do paciente
    Then os dados do paciente são exibidos
    And o saldo de 20 créditos é mostrado

    # Confirmação do atendimento
    When o funcionário confirma o atendimento
    And seleciona "Consulta Geral" (5 créditos)
    Then a transação é registrada
    And o saldo do paciente é atualizado para 15 créditos
    And uma notificação é enviada ao paciente

    # Verificação no Admin
    Given o administrador está logado no portal web
    When o administrador acessa "Transações"
    Then a nova transação aparece na lista
    And mostra "João Silva - Clínica Norte - 5 créditos"
```

#### TSI002: Tratamento de Erros - QR Code Expirado
```gherkin
Scenario: QR Code expirado
  Given um QR Code foi gerado há 35 minutos
  When a clínica tenta validar o QR Code
  Then o sistema retorna erro "QR Code expirado"
  And solicita que o paciente gere um novo código
```

#### TSI003: Concorrência - Uso Simultâneo
```gherkin
Scenario: Tentativa de uso simultâneo do mesmo QR Code
  Given um QR Code válido foi gerado
  And a "Clínica A" validou o QR Code
  When a "Clínica B" tenta validar o mesmo QR Code
  Then o sistema retorna erro "QR Code já utilizado"
  And a segunda tentativa é bloqueada
```

---

## Cenários de Teste Críticos

### Segurança

#### SEC001: Tentativa de Reutilização de QR Code
- **Objetivo**: Validar que QR Codes não podem ser reutilizados
- **Passos**:
  1. Gerar QR Code válido
  2. Usar QR Code em uma clínica
  3. Tentar usar o mesmo QR Code novamente
- **Resultado Esperado**: Sistema bloqueia segunda tentativa

#### SEC002: Acesso não Autorizado a APIs
- **Objetivo**: Validar autenticação JWT
- **Passos**:
  1. Tentar acessar endpoints sem token
  2. Tentar acessar com token expirado
  3. Tentar acessar com token inválido
- **Resultado Esperado**: Retorno 401 Unauthorized

### Performance

#### PERF001: Carga no Dashboard
- **Objetivo**: Validar performance com volume de dados
- **Cenário**: 
  - 10.000 pacientes
  - 100.000 transações
  - 50 clínicas ativas
- **Critério**: Dashboard carrega em < 3 segundos

#### PERF002: Geração de QR Code sob Carga
- **Objetivo**: Validar geração simultânea
- **Cenário**: 100 requisições simultâneas
- **Critério**: 
  - Tempo de resposta < 500ms
  - Taxa de sucesso > 99%

### Resiliência

#### RES001: Falha do Redis
- **Objetivo**: Validar comportamento sem cache
- **Cenário**: Redis indisponível
- **Resultado Esperado**: 
  - Sistema continua operacional
  - Log de erro gerado
  - Performance degradada aceitável

#### RES002: Indisponibilidade do Firebase
- **Objetivo**: Validar fallback de autenticação
- **Cenário**: Firebase Auth fora do ar
- **Resultado Esperado**:
  - Usuários existentes conseguem fazer login com tokens válidos
  - Novos logins são bloqueados com mensagem apropriada

---

## Matriz de Rastreabilidade

| Requisito | Caso de Uso | Teste Unitário | Teste Integração | Teste E2E |
|-----------|-------------|----------------|------------------|-----------|
| Autenticação Firebase | UC001, UC007, UC011 | TU001, TU004, TU006 | TI001 | TE001, TE002 |
| Gestão de Planos | UC003, UC012 | TU003 | - | TE001 |
| QR Code | UC008, UC009, UC013, UC014 | TU002 | TI002 | TSI001 |
| Dashboard | UC004 | TU005 | - | TE001 |
| Transações | UC005, UC010 | TU003 | TI002 | TSI001 |
| Segurança | Todos | - | - | SEC001, SEC002 |
| Performance | UC004, UC009 | - | - | PERF001, PERF002 |
| Resiliência | UC007, UC008 | - | - | RES001, RES002 |

---

## Checklist de Validação

### Pré-Produção
- [ ] Todos os testes unitários passando (cobertura > 80%)
- [ ] Testes de integração executados com sucesso
- [ ] Testes E2E em ambiente de staging
- [ ] Testes de carga realizados
- [ ] Testes de segurança (penetration testing)
- [ ] Validação de backup e recovery
- [ ] Documentação atualizada

### Smoke Tests Pós-Deploy
1. [ ] Login via email/senha (Web Admin)
2. [ ] Login via Google (Web Admin)
3. [ ] Visualização do Dashboard
4. [ ] Login no app mobile (Paciente)
5. [ ] Geração de QR Code
6. [ ] Validação de QR Code (Clínica)
7. [ ] Consulta de histórico

### Monitoramento Contínuo
- Uptime da API > 99.9%
- Tempo de resposta médio < 200ms
- Taxa de erro < 0.1%
- Alertas configurados para:
  - Falhas de autenticação em massa
  - Uso anormal de QR Codes
  - Performance degradada
  - Erros de integração Firebase

---

## Conclusão

Este documento estabelece uma base sólida para garantir a qualidade do sistema SingleClin através de casos de uso bem definidos e uma estratégia de testes abrangente. A execução sistemática destes testes, combinada com monitoramento contínuo, assegurará a confiabilidade e segurança da plataforma.

### Próximos Passos
1. Implementar automação dos testes
2. Configurar pipeline CI/CD com gates de qualidade
3. Estabelecer métricas de cobertura mínima
4. Treinar equipe nos procedimentos de teste
5. Realizar testes de aceitação com usuários reais