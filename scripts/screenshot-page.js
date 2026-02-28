#!/usr/bin/env node
/**
 * Screenshot Page — Captura screenshot full-page de qualquer URL via Playwright
 *
 * Uso:
 *   node screenshot-page.js --url="https://exemplo.com" --output="./screenshot.png"
 *   node screenshot-page.js --url="https://exemplo.com" --output="./dir/" --width=1920
 *   node screenshot-page.js --url="https://exemplo.com" --download --download-output="./downloads"
 *
 * Opcoes:
 *   --url         URL da pagina (obrigatorio)
 *   --output      Caminho do arquivo PNG ou diretorio (default: ./screenshot.png)
 *   --width       Largura do viewport (default: 1920)
 *   --full-page   Screenshot da pagina inteira (default: true)
 *   --download    Ativar modo download — baixa arquivos linkados (PDFs, etc.)
 *   --download-output  Diretorio para downloads (default: ./downloads)
 *   --wait        Tempo extra de espera em ms (default: 2000)
 *
 * Dependencias: npx playwright install chromium (primeira execucao)
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

function parseArgs() {
  const args = {};
  process.argv.slice(2).forEach(arg => {
    const [key, ...valueParts] = arg.replace(/^--/, '').split('=');
    args[key] = valueParts.length ? valueParts.join('=') : true;
  });
  return args;
}

async function main() {
  const args = parseArgs();
  const url = args.url;
  const width = parseInt(args.width || '1920');
  const fullPage = args['full-page'] !== 'false';
  const waitTime = parseInt(args.wait || '2000');
  const downloadMode = args.download !== undefined;
  const downloadOutput = args['download-output'] || './downloads';

  if (!url) {
    console.error('Uso: node screenshot-page.js --url="https://..." [--output="./screenshot.png"]');
    process.exit(1);
  }

  // Determinar output path
  let outputPath = args.output || './screenshot.png';
  if (outputPath.endsWith('/') || (fs.existsSync(outputPath) && fs.statSync(outputPath).isDirectory())) {
    const filename = url.replace(/https?:\/\//, '').replace(/[^a-zA-Z0-9]/g, '_').substring(0, 80) + '.png';
    outputPath = path.join(outputPath, filename);
  }

  // Garantir diretorio existe
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  if (downloadMode && !fs.existsSync(downloadOutput)) fs.mkdirSync(downloadOutput, { recursive: true });

  console.log(`Screenshot: ${url}`);
  console.log(`Output: ${outputPath}`);
  console.log(`Viewport: ${width}x1080`);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width, height: 1080 },
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  });

  // Interceptar downloads
  if (downloadMode) {
    context.on('download', async (download) => {
      const filename = download.suggestedFilename();
      const filepath = path.join(downloadOutput, filename);
      await download.saveAs(filepath);
      console.log(`Download salvo: ${filepath}`);
    });
  }

  const page = await context.newPage();

  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  } catch (e) {
    console.log(`Timeout networkidle, tentando domcontentloaded...`);
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
    } catch (e2) {
      console.error(`Falha ao carregar: ${e2.message}`);
      await browser.close();
      process.exit(1);
    }
  }

  // Esperar conteudo carregar
  await page.waitForTimeout(waitTime);

  // Se modo download, clicar em links de download
  if (downloadMode) {
    const downloadLinks = await page.evaluate(() => {
      const links = [];
      document.querySelectorAll('a[href]').forEach(a => {
        const href = a.href.toLowerCase();
        const text = (a.innerText || '').toLowerCase();
        if (href.endsWith('.pdf') || href.endsWith('.zip') || href.endsWith('.epub') ||
            text.includes('download') || text.includes('baixar')) {
          links.push(a.href);
        }
      });
      return links;
    });

    if (downloadLinks.length > 0) {
      console.log(`Encontrados ${downloadLinks.length} links de download`);
      for (const link of downloadLinks) {
        try {
          const [download] = await Promise.all([
            page.waitForEvent('download', { timeout: 10000 }).catch(() => null),
            page.evaluate(href => {
              const a = document.createElement('a');
              a.href = href;
              a.download = '';
              document.body.appendChild(a);
              a.click();
              a.remove();
            }, link),
          ]);
          if (download) {
            const filename = download.suggestedFilename();
            const filepath = path.join(downloadOutput, filename);
            await download.saveAs(filepath);
            console.log(`Baixado: ${filepath}`);
          }
        } catch (e) {
          console.log(`Falha ao baixar ${link}: ${e.message}`);
        }
      }
    }
  }

  // Screenshot
  await page.screenshot({ path: outputPath, fullPage });
  console.log(`Screenshot salvo: ${outputPath}`);

  // Extrair info basica
  const info = await page.evaluate(() => {
    const h1 = document.querySelector('h1');
    return {
      title: document.title,
      headline: h1 ? h1.innerText.trim() : null,
      hasForm: document.querySelectorAll('form').length > 0,
      hasVideo: document.querySelectorAll('video, iframe[src*="youtube"], iframe[src*="vimeo"]').length > 0,
    };
  });

  console.log(`Titulo: ${info.title}`);
  if (info.headline) console.log(`Headline: ${info.headline}`);
  console.log(`Form: ${info.hasForm ? 'Sim' : 'Nao'} | Video: ${info.hasVideo ? 'Sim' : 'Nao'}`);

  await browser.close();
}

main().catch(err => {
  console.error('Erro fatal:', err.message);
  process.exit(1);
});
