#!/usr/bin/env node
/**
 * Funnel Crawler — Navegacao automatizada de funis via Playwright
 *
 * Uso:
 *   node funnel-crawler.js --url="https://exemplo.com/lp" --output="./funil-infiltrado"
 *   node funnel-crawler.js --url="https://exemplo.com/lp" --output="./funil-infiltrado" --max-pages=10 --fill-forms
 *   node funnel-crawler.js --url="https://exemplo.com/lp" --output="./funil-infiltrado" --download --download-output="./ativos"
 *
 * Funcionalidades:
 *   - Navega paginas sequencialmente
 *   - Tira screenshots full-page (PNG)
 *   - Preenche formularios com dados ficticios
 *   - Salva dados de cada pagina em JSON
 *   - Gera mapa Mermaid automaticamente
 *   - Pode baixar arquivos (PDFs, etc.) encontrados na pagina
 *
 * Dependencias: npx playwright install chromium (primeira execucao)
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Dados ficticios padrao para preenchimento de formularios
const FAKE_DATA = {
  name: 'Pesquisa Mercado',
  first_name: 'Pesquisa',
  last_name: 'Mercado',
  email: 'pesquisa@exemplo.com',
  phone: '11999999999',
  tel: '11999999999',
  whatsapp: '11999999999',
  company: 'Pesquisa de Mercado Ltda',
  empresa: 'Pesquisa de Mercado Ltda',
  city: 'Sao Paulo',
  cidade: 'Sao Paulo',
  state: 'SP',
  website: 'https://exemplo.com',
  message: 'Pesquisa de mercado e benchmarking',
  mensagem: 'Pesquisa de mercado e benchmarking',
  revenue: '10000-50000',
  faturamento: '10000-50000',
};

// Parse argumentos CLI
function parseArgs() {
  const args = {};
  process.argv.slice(2).forEach(arg => {
    const [key, ...valueParts] = arg.replace(/^--/, '').split('=');
    args[key] = valueParts.length ? valueParts.join('=') : true;
  });
  return args;
}

// Criar diretorios de output
function ensureOutputDirs(outputDir) {
  const dirs = [
    outputDir,
    path.join(outputDir, 'screenshots'),
    path.join(outputDir, 'dados'),
  ];
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  });
}

// Determinar valor para um campo de formulario baseado no tipo e label
function getFieldValue(field) {
  const { type, name, placeholder, label } = field;
  const hint = (name + ' ' + (placeholder || '') + ' ' + (label || '')).toLowerCase();

  if (type === 'email' || hint.includes('email') || hint.includes('e-mail')) return FAKE_DATA.email;
  if (hint.includes('whatsapp') || hint.includes('wpp') || hint.includes('zap')) return FAKE_DATA.whatsapp;
  if (type === 'tel' || hint.includes('telefone') || hint.includes('phone') || hint.includes('celular')) return FAKE_DATA.phone;
  if (hint.includes('empresa') || hint.includes('company')) return FAKE_DATA.company;
  if (hint.includes('cidade') || hint.includes('city')) return FAKE_DATA.city;
  if (hint.includes('estado') || hint.includes('state') || hint.includes('uf')) return FAKE_DATA.state;
  if (hint.includes('site') || hint.includes('website') || hint.includes('url')) return FAKE_DATA.website;
  if (hint.includes('faturamento') || hint.includes('revenue') || hint.includes('receita')) return FAKE_DATA.revenue;
  if (hint.includes('sobrenome') || hint.includes('last')) return FAKE_DATA.last_name;
  if (hint.includes('nome') || hint.includes('name') || hint.includes('first')) return FAKE_DATA.name;
  if (type === 'textarea' || hint.includes('mensagem') || hint.includes('message') || hint.includes('desafio') || hint.includes('objetivo')) return FAKE_DATA.message;
  if (type === 'number') return '30';
  if (type === 'url') return FAKE_DATA.website;

  return FAKE_DATA.name;
}

// Extrair dados de uma pagina
async function extractPageData(page, step, screenshotPath) {
  return await page.evaluate(({ step, screenshotPath }) => {
    const data = {
      step,
      url: window.location.href,
      type: 'UNKNOWN',
      screenshot: screenshotPath,
      headline: '',
      subheadline: '',
      ctas: [],
      form_fields: [],
      price: null,
      timer: false,
      testimonials: 0,
      links_found: [],
    };

    // Headline
    const h1 = document.querySelector('h1');
    if (h1) data.headline = h1.innerText.trim();
    else {
      const h2 = document.querySelector('h2');
      if (h2) data.headline = h2.innerText.trim();
    }

    // Sub-headline
    const h2s = document.querySelectorAll('h2');
    if (h2s.length > 0 && h1) data.subheadline = h2s[0].innerText.trim();

    // CTAs
    document.querySelectorAll('button, input[type="submit"], a.btn, a.button, [role="button"]').forEach(el => {
      const text = (el.innerText || el.value || '').trim();
      if (text && text.length < 100) data.ctas.push(text);
    });

    // Form fields
    document.querySelectorAll('form input, form select, form textarea').forEach(el => {
      if (el.type === 'hidden' || el.type === 'submit') return;
      const label = el.labels?.[0]?.innerText?.trim() || '';
      data.form_fields.push({
        name: el.name || el.id || '',
        type: el.type || el.tagName.toLowerCase(),
        label,
        placeholder: el.placeholder || '',
        required: el.required,
      });
    });

    // Type classification
    const url = window.location.href.toLowerCase();
    const html = document.body.innerText.toLowerCase();
    if (data.form_fields.length > 0) data.type = 'FORM';
    if (url.includes('checkout') || url.includes('pay.') || url.includes('compra')) data.type = 'CK';
    if (url.includes('obrigado') || url.includes('thankyou') || url.includes('thank-you')) data.type = 'TY';
    if (url.includes('calendar') || url.includes('calendly') || url.includes('tidycal') || url.includes('agend')) data.type = 'CALENDAR';
    if (document.querySelector('video, iframe[src*="youtube"], iframe[src*="vimeo"], [class*="vturb"], vturb-smartplayer')) data.type = 'VSL';
    if (data.form_fields.length === 0 && (html.includes('comprar') || html.includes('matricul'))) data.type = 'PV';
    if (data.form_fields.length > 0 && data.form_fields.length <= 2) data.type = 'LP';

    // Price detection
    const priceMatch = document.body.innerHTML.match(/R\$\s*[\d.,]+/);
    if (priceMatch) data.price = priceMatch[0];

    // Timer/urgency
    data.timer = !!(document.querySelector('[class*="timer"], [class*="countdown"], [id*="timer"]'));

    // Testimonials
    data.testimonials = document.querySelectorAll('[class*="testimonial"], [class*="depoimento"]').length;

    // Links
    document.querySelectorAll('a[href]').forEach(a => {
      const href = a.href;
      if (href && !href.startsWith('javascript:') && !href.startsWith('#')) {
        data.links_found.push(href);
      }
    });
    data.links_found = [...new Set(data.links_found)].slice(0, 20);

    return data;
  }, { step, screenshotPath });
}

// Gerar mapa Mermaid a partir dos dados de paginas
function generateMermaidMap(pagesData) {
  let mermaid = 'graph TD\n';
  const colors = {
    LP: '#4CAF50', FORM: '#2196F3', CALENDAR: '#FF9800', VSL: '#E91E63',
    PV: '#9C27B0', CK: '#F44336', TY: '#00BCD4', UNKNOWN: '#607D8B',
  };

  pagesData.forEach((page, i) => {
    const id = `P${i + 1}`;
    const label = `${i + 1}. ${page.type}: ${(page.headline || 'Sem titulo').substring(0, 40)}`;
    mermaid += `    ${id}["${label.replace(/"/g, "'")}"]\n`;
  });

  pagesData.forEach((page, i) => {
    if (i < pagesData.length - 1) {
      const from = `P${i + 1}`;
      const to = `P${i + 2}`;
      const action = page.type === 'FORM' || page.type === 'LP' ? 'Preenche form' :
                     page.type === 'CALENDAR' ? 'Agenda' :
                     page.type === 'VSL' ? 'Assiste' : 'Navega';
      mermaid += `    ${from} -->|"${action}"| ${to}\n`;
    }
  });

  mermaid += '\n';
  pagesData.forEach((page, i) => {
    const id = `P${i + 1}`;
    const color = colors[page.type] || colors.UNKNOWN;
    mermaid += `    style ${id} fill:${color},color:#fff\n`;
  });

  return mermaid;
}

// Main
async function main() {
  const args = parseArgs();
  const url = args.url;
  const outputDir = args.output || './funil-infiltrado';
  const maxPages = parseInt(args['max-pages'] || '10');
  const fillForms = args['fill-forms'] !== undefined ? args['fill-forms'] !== 'false' : true;
  const downloadMode = args.download !== undefined;
  const downloadOutput = args['download-output'] || path.join(outputDir, 'downloads');

  if (!url) {
    console.error('Uso: node funnel-crawler.js --url="https://..." [--output="./dir"] [--max-pages=10] [--fill-forms] [--download]');
    process.exit(1);
  }

  console.log(`Funnel Crawler iniciado`);
  console.log(`URL: ${url}`);
  console.log(`Output: ${outputDir}`);
  console.log(`Max paginas: ${maxPages}`);
  console.log(`Preencher forms: ${fillForms}`);

  ensureOutputDirs(outputDir);
  if (downloadMode && !fs.existsSync(downloadOutput)) fs.mkdirSync(downloadOutput, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  });

  // Interceptar downloads se modo download ativo
  if (downloadMode) {
    context.on('download', async (download) => {
      const filename = download.suggestedFilename();
      const filepath = path.join(downloadOutput, filename);
      await download.saveAs(filepath);
      console.log(`  Download salvo: ${filepath}`);
    });
  }

  const page = await context.newPage();
  const visitedUrls = new Set();
  const pagesData = [];
  let currentUrl = url;

  for (let step = 1; step <= maxPages; step++) {
    // Detectar loop
    if (visitedUrls.has(currentUrl)) {
      console.log(`Loop detectado (URL repetida): ${currentUrl}`);
      break;
    }
    visitedUrls.add(currentUrl);

    console.log(`\n--- Pagina ${step}: ${currentUrl} ---`);

    try {
      await page.goto(currentUrl, { waitUntil: 'networkidle', timeout: 30000 });
    } catch (e) {
      console.log(`  Timeout ao carregar (tentando domcontentloaded)...`);
      try {
        await page.goto(currentUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
      } catch (e2) {
        console.log(`  Falha ao carregar pagina: ${e2.message}`);
        break;
      }
    }

    // Aguardar conteudo carregar
    await page.waitForTimeout(2000);

    // Screenshot
    const screenshotFile = `pagina-${step}.png`;
    const screenshotPath = path.join(outputDir, 'screenshots', screenshotFile);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    console.log(`  Screenshot: ${screenshotPath}`);

    // Extrair dados
    const pageData = await extractPageData(page, step, `screenshots/${screenshotFile}`);
    pagesData.push(pageData);
    console.log(`  Tipo: ${pageData.type} | Headline: ${(pageData.headline || '').substring(0, 60)}`);
    console.log(`  Forms: ${pageData.form_fields.length} campos | CTAs: ${pageData.ctas.length}`);
    if (pageData.price) console.log(`  Preco: ${pageData.price}`);

    // Salvar JSON
    const jsonPath = path.join(outputDir, 'dados', `pagina-${step}.json`);
    fs.writeFileSync(jsonPath, JSON.stringify(pageData, null, 2));

    // Detectar pagina terminal
    if (pageData.type === 'CK') {
      console.log(`  CHECKOUT detectado — parando (nao vamos comprar)`);
      break;
    }
    if (pageData.type === 'TY') {
      console.log(`  THANK YOU detectado — funil completo`);
      break;
    }
    if (pageData.type === 'CALENDAR') {
      console.log(`  CALENDARIO detectado — screenshot salvo, nao vamos agendar`);
      break;
    }

    // Preencher formulario se existir
    if (fillForms && pageData.form_fields.length > 0) {
      console.log(`  Preenchendo ${pageData.form_fields.length} campos...`);

      for (const field of pageData.form_fields) {
        try {
          const selector = field.name
            ? `[name="${field.name}"]`
            : field.label
            ? `input, select, textarea`
            : null;

          if (!selector) continue;

          const element = await page.$(selector.includes(',') ? `form ${selector}` : selector);
          if (!element) continue;

          const tagName = await element.evaluate(el => el.tagName.toLowerCase());

          if (tagName === 'select') {
            const options = await element.evaluate(el =>
              Array.from(el.options).filter(o => o.value).map(o => o.value)
            );
            if (options.length > 0) {
              await element.selectOption(options[Math.min(1, options.length - 1)]);
            }
          } else if (field.type === 'checkbox' || field.type === 'radio') {
            const isChecked = await element.isChecked();
            if (!isChecked) await element.check();
          } else {
            const value = getFieldValue(field);
            await element.fill(value);
          }
        } catch (e) {
          // Campo nao encontrado, seguir
        }
      }

      // Submeter formulario
      try {
        const submitBtn = await page.$('form button[type="submit"], form input[type="submit"], form button:not([type])');
        if (submitBtn) {
          console.log(`  Submetendo formulario...`);
          await Promise.all([
            page.waitForNavigation({ timeout: 15000 }).catch(() => {}),
            submitBtn.click(),
          ]);
          await page.waitForTimeout(3000);
          currentUrl = page.url();
          console.log(`  Redirecionado para: ${currentUrl}`);
          continue;
        }
      } catch (e) {
        console.log(`  Erro ao submeter: ${e.message}`);
      }
    }

    // Se nao tem formulario, tentar encontrar proximo link/botao principal
    const nextUrl = await page.evaluate(() => {
      const btns = document.querySelectorAll('a.btn, a.button, a[class*="cta"], a[class*="primary"]');
      for (const btn of btns) {
        const href = btn.href;
        if (href && !href.startsWith('javascript:') && !href.startsWith('#') && !href.includes('login')) {
          return href;
        }
      }
      return null;
    });

    if (nextUrl && !visitedUrls.has(nextUrl)) {
      currentUrl = nextUrl;
    } else {
      console.log(`  Sem proximo link encontrado — parando`);
      break;
    }
  }

  // Gerar mapa Mermaid
  const mermaidContent = generateMermaidMap(pagesData);
  const mapPath = path.join(outputDir, 'mapa-visual.md');
  const mapContent = `# Mapa do Funil
Data: ${new Date().toISOString().split('T')[0]}
URL de entrada: ${url}

## Diagrama de Fluxo

\`\`\`mermaid
${mermaidContent}
\`\`\`

## Detalhes por Pagina

${pagesData.map((p, i) => `### Pagina ${i + 1}: ${p.type}
- **URL:** ${p.url}
- **Screenshot:** ${p.screenshot}
- **Headline:** ${p.headline || 'N/A'}
- **Sub-headline:** ${p.subheadline || 'N/A'}
- **CTAs:** ${p.ctas.join(', ') || 'N/A'}
- **Preco:** ${p.price || 'N/A'}
- **Timer/Urgencia:** ${p.timer ? 'Sim' : 'Nao'}
- **Campos do form:** ${p.form_fields.length > 0 ? p.form_fields.map(f => `${f.label || f.name} (${f.type})`).join(', ') : 'Nenhum'}
`).join('\n')}

## Resumo
- **Total de paginas:** ${pagesData.length}
- **Tipo de funil:** ${pagesData.map(p => p.type).join(' → ')}
- **Tem VSL:** ${pagesData.some(p => p.type === 'VSL') ? 'Sim' : 'Nao'}
- **Tem formulario:** ${pagesData.some(p => p.form_fields.length > 0) ? 'Sim' : 'Nao'}
- **Tem timer:** ${pagesData.some(p => p.timer) ? 'Sim' : 'Nao'}
`;

  fs.writeFileSync(mapPath, mapContent);
  console.log(`\nMapa visual salvo: ${mapPath}`);
  console.log(`Total de paginas capturadas: ${pagesData.length}`);

  await browser.close();
}

main().catch(err => {
  console.error('Erro fatal:', err.message);
  process.exit(1);
});
