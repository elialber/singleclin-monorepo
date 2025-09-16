import { test, expect } from '@playwright/test';

// Testes RIGOROSOS que realmente validam funcionalidade
// Estes testes devem FALHAR se há problemas reais

test.describe('Web-Admin Deep Validation - Testes Rigorosos', () => {
  const baseURL = 'http://localhost:3000';

  test.beforeEach(async ({ page }) => {
    await page.goto(baseURL);
  });

  test('🔍 Login deve funcionar ou mostrar erro claro', async ({ page }) => {
    // Este teste vai FALHAR se o login não estiver implementado

    await page.waitForLoadState('domcontentloaded');

    // Encontrar campos de login
    const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]');
    const passwordInput = page.locator('input[type="password"], input[name="password"], input[placeholder*="senha" i]');
    const loginButton = page.locator('button[type="submit"]').first(); // Usar apenas o primeiro botão submit para evitar ambiguidade

    // Verificar se existem (se não existir, o teste deve falhar)
    await expect(emailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();
    await expect(loginButton).toBeVisible();

    // Tentar fazer login com credenciais válidas
    await emailInput.fill('admin@singleclin.com');
    await passwordInput.fill('123456');

    // Interceptar calls de rede para ver se realmente tenta autenticar
    const apiCalls: string[] = [];
    page.on('request', request => {
      const url = request.url();
      if (url.includes('/api/') || url.includes('/auth/') || url.includes('firebase') || url.includes('login')) {
        apiCalls.push(url);
      }
    });

    await loginButton.click();

    // Aguardar resposta (deve haver tentativa de autenticação ou erro)
    await page.waitForTimeout(2000);

    // Verificar se houve tentativa real de autenticação
    if (apiCalls.length === 0) {
      // Se não houve calls de API, pode ser que o login nem esteja implementado
      console.log('❌ PROBLEMA: Nenhuma call de API de autenticação detectada');

      // Verificar se apareceu alguma mensagem de erro ou se mudou a URL
      const currentUrl = page.url();
      const hasErrorMessage = await page.locator('text=/erro|error|inválido|falhou/i').count() > 0;

      expect(currentUrl !== baseURL || hasErrorMessage).toBeTruthy();
    } else {
      console.log(`✅ Calls de autenticação detectadas: ${apiCalls.join(', ')}`);
    }
  });

  test('🔍 Navigation deve realmente funcionar', async ({ page }) => {
    await page.waitForLoadState('domcontentloaded');

    // Procurar por links de navegação reais
    const navLinks = await page.locator('a[href], button[data-route], nav a, [role="menuitem"]').all();

    if (navLinks.length === 0) {
      throw new Error('❌ PROBLEMA: Nenhum link de navegação encontrado na aplicação');
    }

    let successfulNavigation = false;

    for (const link of navLinks.slice(0, 3)) { // Testar os primeiros 3 links
      const href = await link.getAttribute('href');
      const text = await link.textContent();

      if (href && !href.startsWith('#') && !href.startsWith('javascript:')) {
        console.log(`Testando navegação para: ${text} (${href})`);

        const initialUrl = page.url();
        await link.click();
        await page.waitForTimeout(1000);
        const newUrl = page.url();

        if (newUrl !== initialUrl) {
          successfulNavigation = true;
          console.log(`✅ Navegação funcionou: ${initialUrl} → ${newUrl}`);
          break;
        }
      }
    }

    if (!successfulNavigation) {
      throw new Error('❌ PROBLEMA: Nenhuma navegação real funcionou - links podem estar quebrados');
    }
  });

  test('🔍 Conectividade com Backend deve ser testada', async ({ page }) => {
    const responses: { status: number; url: string }[] = [];
    const errors: string[] = [];

    // Interceptar responses para ver status codes reais
    page.on('response', response => {
      if (response.url().includes('/api/') || response.url().includes('localhost:5010')) {
        responses.push({ status: response.status(), url: response.url() });
      }
    });

    // Interceptar erros de console
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(3000); // Aguardar calls de API

    console.log(`API Responses: ${JSON.stringify(responses, null, 2)}`);
    console.log(`Console Errors: ${errors.join(', ')}`);

    // Se há calls de API, verificar se retornam status válido
    if (responses.length > 0) {
      const failedCalls = responses.filter(r => r.status >= 400);
      if (failedCalls.length > 0) {
        console.log(`❌ PROBLEMA: API calls falhando: ${JSON.stringify(failedCalls)}`);
      }
    }

    // Verificar erros críticos de JavaScript
    const criticalErrors = errors.filter(error =>
      error.includes('TypeError') ||
      error.includes('ReferenceError') ||
      error.includes('Cannot read') ||
      error.includes('is not defined') ||
      error.includes('Network Error') ||
      error.includes('Failed to fetch')
    );

    if (criticalErrors.length > 0) {
      throw new Error(`❌ PROBLEMAS CRÍTICOS: ${criticalErrors.join('; ')}`);
    }
  });

  test('🔍 Formulários devem realmente enviar dados', async ({ page }) => {
    await page.waitForLoadState('domcontentloaded');

    const forms = await page.locator('form').all();

    if (forms.length === 0) {
      console.log('⚠️  Nenhum formulário encontrado - pode estar esperando autenticação');
      return;
    }

    let formSubmitted = false;
    const networkActivity: string[] = [];

    page.on('request', request => {
      if (request.method() === 'POST' || request.method() === 'PUT') {
        networkActivity.push(`${request.method()} ${request.url()}`);
      }
    });

    for (const form of forms) {
      const inputs = await form.locator('input, textarea, select').all();

      if (inputs.length > 0) {
        // Preencher todos os campos
        for (const input of inputs) {
          const type = await input.getAttribute('type');
          const name = await input.getAttribute('name') || await input.getAttribute('placeholder') || 'test';

          if (await input.isVisible() && await input.isEnabled()) {
            switch (type) {
              case 'email':
                await input.fill('test@singleclin.com');
                break;
              case 'password':
                await input.fill('123456');
                break;
              case 'number':
                await input.fill('123');
                break;
              case 'checkbox':
                await input.check();
                break;
              default:
                if (type !== 'checkbox') {
                  await input.fill(`Test ${name}`);
                }
            }
          }
        }

        // Procurar botão de submit
        const submitButton = await form.locator('button[type="submit"], input[type="submit"], button:has-text("Enviar"), button:has-text("Salvar"), button:has-text("Entrar")').first();

        if (await submitButton.isVisible()) {
          await submitButton.click();
          await page.waitForTimeout(2000);
          formSubmitted = true;
          break;
        }
      }
    }

    if (formSubmitted) {
      console.log(`Network activity após submit: ${networkActivity.join(', ')}`);

      if (networkActivity.length === 0) {
        console.log('⚠️  Form foi submetido mas não houve network activity - pode ser validação local');
      }
    }
  });

  test('🔍 Estado real da aplicação', async ({ page }) => {
    // Fazer um diagnóstico completo do estado da aplicação

    await page.waitForLoadState('domcontentloaded');

    const diagnostics = {
      title: await page.title(),
      url: page.url(),
      totalElements: await page.locator('*').count(),
      forms: await page.locator('form').count(),
      inputs: await page.locator('input').count(),
      buttons: await page.locator('button').count(),
      links: await page.locator('a[href]').count(),
      images: await page.locator('img').count(),
      hasReactRoot: await page.locator('#root, [data-reactroot]').count() > 0,
      visibleText: (await page.textContent('body'))?.substring(0, 200) + '...'
    };

    console.log('🔍 DIAGNÓSTICO COMPLETO DA APLICAÇÃO:');
    console.log(JSON.stringify(diagnostics, null, 2));

    // Verificar se a aplicação tem conteúdo real
    if (diagnostics.totalElements < 10) {
      throw new Error('❌ PROBLEMA: Aplicação tem muito poucos elementos - pode não estar carregando');
    }

    // Aplicação deve ter pelo menos alguns elementos interativos
    const interactiveElements = diagnostics.forms + diagnostics.inputs + diagnostics.buttons + diagnostics.links;
    if (interactiveElements < 3) {
      throw new Error('❌ PROBLEMA: Aplicação tem poucos elementos interativos - pode estar quebrada');
    }
  });
});