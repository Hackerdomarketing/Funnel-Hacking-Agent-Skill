# ============================================================
# Instalador da Skill: Funnel Hacking Agent (Windows)
# Repositório: https://github.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill
# ============================================================

$ErrorActionPreference = "Stop"

$REPO_RAW   = "https://raw.githubusercontent.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill/main"
$SKILL_DIR  = "$env:USERPROFILE\.claude\skills\funnel-hacking"
$CLAUDE_MD  = "$env:USERPROFILE\.claude\CLAUDE.md"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Instalando: Funnel Hacking Agent Skill       " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── PASSO 1: Criar pastas ───────────────────────────────────
Write-Host "▶ Criando pastas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$SKILL_DIR\scripts"    | Out-Null
New-Item -ItemType Directory -Force -Path "$SKILL_DIR\references" | Out-Null
New-Item -ItemType Directory -Force -Path "$SKILL_DIR\assets"     | Out-Null
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
Write-Host "  ✓ Pastas criadas" -ForegroundColor Green

# ── PASSO 2: Baixar arquivos principais ────────────────────
Write-Host "▶ Baixando arquivos da skill..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "$REPO_RAW/SKILL.md"     -OutFile "$SKILL_DIR\SKILL.md"     -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/README.md"    -OutFile "$SKILL_DIR\README.md"    -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/package.json" -OutFile "$SKILL_DIR\package.json" -UseBasicParsing

Write-Host "  ✓ Arquivos principais baixados" -ForegroundColor Green

# ── PASSO 3: Baixar scripts ────────────────────────────────
Write-Host "▶ Baixando scripts..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "$REPO_RAW/scripts/google-dork-funnel.sh" -OutFile "$SKILL_DIR\scripts\google-dork-funnel.sh" -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/scripts/download-vsl.sh"       -OutFile "$SKILL_DIR\scripts\download-vsl.sh"       -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/scripts/funnel-crawler.js"     -OutFile "$SKILL_DIR\scripts\funnel-crawler.js"     -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/scripts/screenshot-page.js"    -OutFile "$SKILL_DIR\scripts\screenshot-page.js"    -UseBasicParsing

Write-Host "  ✓ Scripts prontos" -ForegroundColor Green

# ── PASSO 4: Baixar referências ────────────────────────────
Write-Host "▶ Baixando documentação de referência..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "$REPO_RAW/references/metodologia-completa.md" -OutFile "$SKILL_DIR\references\metodologia-completa.md" -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/references/fallbacks-e-falhas.md"   -OutFile "$SKILL_DIR\references\fallbacks-e-falhas.md"   -UseBasicParsing

Write-Host "  ✓ Referências baixadas" -ForegroundColor Green

# ── PASSO 5: Instalar dependências Node.js (opcional) ──────
Write-Host "▶ Verificando Node.js..." -ForegroundColor Yellow

$npmAvailable = Get-Command npm -ErrorAction SilentlyContinue

if ($npmAvailable) {
    Write-Host "  Node.js encontrado. Instalando dependências..."
    Set-Location $SKILL_DIR
    npm install --silent 2>$null
    Write-Host "  ✓ Dependências instaladas (Playwright disponível)" -ForegroundColor Green
} else {
    Write-Host "  Node.js não encontrado — tudo bem! A skill funciona normalmente."
    Write-Host "  (Apenas o download de VSL bloqueada ficará desativado)"
}

# ── PASSO 6: Configurar triggers no CLAUDE.md ──────────────
Write-Host "▶ Configurando ativação automática no Claude Code..." -ForegroundColor Yellow

# Criar CLAUDE.md se não existir
if (-not (Test-Path $CLAUDE_MD)) {
    New-Item -ItemType File -Force -Path $CLAUDE_MD | Out-Null
}

# Adicionar seção de triggers apenas se ainda não existir
$claudeContent = Get-Content $CLAUDE_MD -Raw -ErrorAction SilentlyContinue

if (-not ($claudeContent -match "funnel-hacking")) {
    $triggerBlock = @"


## FUNNEL HACKING

Quando o usuario usar qualquer uma destas frases, ative a skill ``funnel-hacking``:

**Triggers de ativacao:**
- "funnel hacking", "ative o funnel hacking", "hacking de funil"
- "concorrentes", "descobrir concorrentes", "mapear concorrentes"
- "ofertas escaladas", "quem esta escalado"
- "mapear funil", "funil completo", "infiltrar funil"
- "baixar VSL", "capturar VSL", "VSL bloqueada"
- "buscar material", "buscar PDF", "baixar PDF", "encontrar livro"

**REGRA CRITICA:** SEMPRE usar a skill ``funnel-hacking`` quando o usuario pedir.
"@
    Add-Content -Path $CLAUDE_MD -Value $triggerBlock
    Write-Host "  ✓ Triggers configurados" -ForegroundColor Green
} else {
    Write-Host "  ✓ Triggers já estavam configurados" -ForegroundColor Green
}

# ── CONCLUÍDO ───────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   ✅ Funnel Hacking instalado com sucesso!     " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Como usar:"
Write-Host "  1. Abra o Claude Code"
Write-Host "  2. Digite: /funnel-hacking"
Write-Host "  3. Ou escreva naturalmente, ex: ""descobrir concorrentes"""
Write-Host ""
