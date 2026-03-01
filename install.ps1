# ============================================================
# Instalador da Skill: Funnel Hacking Agent (Windows)
# Repositório: https://github.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill
#
# Detecta e instala automaticamente tudo que for necessário:
# Node.js, Claude Code CLI, e a skill completa.
# ============================================================

$ErrorActionPreference = "Continue"

$REPO_RAW   = "https://raw.githubusercontent.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill/main"
$SKILL_DIR  = "$env:USERPROFILE\.claude\skills\funnel-hacking"
$CLAUDE_MD  = "$env:USERPROFILE\.claude\CLAUDE.md"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Instalando: Funnel Hacking Agent Skill       " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Vou verificar tudo que precisa e instalar"
Write-Host "  automaticamente. Pode demorar alguns minutos"
Write-Host "  na primeira vez."
Write-Host ""

# ===============================================================
# FASE 1: VERIFICAR E INSTALAR PRE-REQUISITOS
# ===============================================================

Write-Host "-- FASE 1: Verificando pre-requisitos --" -ForegroundColor Cyan
Write-Host ""

# -- 1.1: Node.js ---------------------------------------------------
Write-Host ">> Verificando Node.js..." -ForegroundColor Yellow

$nodeAvailable = Get-Command node -ErrorAction SilentlyContinue

if ($nodeAvailable) {
    $nodeVersion = node --version
    Write-Host "  OK - Node.js ja esta instalado (versao $nodeVersion)" -ForegroundColor Green
} else {
    Write-Host "  Node.js nao encontrado. Tentando instalar..." -ForegroundColor Yellow

    # Tentar via winget (disponivel no Windows 10/11)
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue

    if ($wingetAvailable) {
        Write-Host "  Instalando Node.js via winget..." -ForegroundColor Yellow
        Write-Host "  (O Windows pode pedir sua confirmacao — clique em Sim)" -ForegroundColor Yellow
        Write-Host ""
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements 2>$null

        # Atualizar PATH para a sessao atual
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
        if ($nodeCheck) {
            Write-Host "  OK - Node.js instalado com sucesso" -ForegroundColor Green
        } else {
            Write-Host "  Nao consegui detectar o Node.js apos instalacao." -ForegroundColor Yellow
            Write-Host "  Pode ser necessario fechar e reabrir o PowerShell." -ForegroundColor Yellow
            Write-Host "  A skill vai funcionar normalmente mesmo sem Node.js." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  winget nao disponivel. Pulando instalacao do Node.js." -ForegroundColor Yellow
        Write-Host "  A skill funciona normalmente sem ele." -ForegroundColor Yellow
        Write-Host "  (Apenas funcoes avancadas ficarao desativadas)" -ForegroundColor Yellow
    }
}
Write-Host ""

# -- 1.2: Claude Code CLI -------------------------------------------
Write-Host ">> Verificando Claude Code..." -ForegroundColor Yellow

if (Test-Path "$env:USERPROFILE\.claude") {
    Write-Host "  OK - Claude Code ja esta configurado" -ForegroundColor Green
} else {
    Write-Host "  Pasta do Claude Code nao encontrada." -ForegroundColor Yellow

    $claudeAvailable = Get-Command claude -ErrorAction SilentlyContinue
    $npmAvailable = Get-Command npm -ErrorAction SilentlyContinue

    if ($claudeAvailable) {
        Write-Host "  OK - Claude Code CLI encontrado. Criando pasta..." -ForegroundColor Green
        New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
    } elseif ($npmAvailable) {
        Write-Host "  Instalando Claude Code via terminal..." -ForegroundColor Yellow
        npm install -g @anthropic-ai/claude-code 2>$null

        $claudeCheck = Get-Command claude -ErrorAction SilentlyContinue
        if ($claudeCheck) {
            Write-Host "  OK - Claude Code CLI instalado com sucesso" -ForegroundColor Green
        } else {
            Write-Host "  Nao consegui instalar o CLI, mas vou criar a pasta." -ForegroundColor Yellow
            Write-Host "  Voce pode usar o Claude Code pelo app desktop ou VS Code." -ForegroundColor Yellow
        }
        New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
    } else {
        Write-Host "  Criando a pasta do Claude Code..." -ForegroundColor Yellow
        Write-Host "  Quando voce abrir o Claude Code pela primeira vez," -ForegroundColor Yellow
        Write-Host "  ele vai reconhecer a skill automaticamente." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
    }
}
Write-Host ""

Write-Host "-- Pre-requisitos prontos! --" -ForegroundColor Green
Write-Host ""

# ===============================================================
# FASE 2: INSTALAR A SKILL
# ===============================================================

Write-Host "-- FASE 2: Instalando a skill --" -ForegroundColor Cyan
Write-Host ""

# -- 2.1: Criar pastas -----------------------------------------------
Write-Host ">> Criando pastas da skill..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$SKILL_DIR\scripts"    | Out-Null
New-Item -ItemType Directory -Force -Path "$SKILL_DIR\references" | Out-Null
New-Item -ItemType Directory -Force -Path "$SKILL_DIR\assets"     | Out-Null
Write-Host "  OK - Pastas criadas" -ForegroundColor Green

# -- 2.2: Baixar arquivos principais ----------------------------------
Write-Host ">> Baixando arquivos da skill..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "$REPO_RAW/SKILL.md"     -OutFile "$SKILL_DIR\SKILL.md"     -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/README.md"    -OutFile "$SKILL_DIR\README.md"    -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/package.json" -OutFile "$SKILL_DIR\package.json" -UseBasicParsing

Write-Host "  OK - Arquivos principais baixados" -ForegroundColor Green

# -- 2.3: Baixar scripts -----------------------------------------------
Write-Host ">> Baixando scripts de automacao..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "$REPO_RAW/scripts/google-dork-funnel.sh" -OutFile "$SKILL_DIR\scripts\google-dork-funnel.sh" -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/scripts/download-vsl.sh"       -OutFile "$SKILL_DIR\scripts\download-vsl.sh"       -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/scripts/funnel-crawler.js"     -OutFile "$SKILL_DIR\scripts\funnel-crawler.js"     -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/scripts/screenshot-page.js"    -OutFile "$SKILL_DIR\scripts\screenshot-page.js"    -UseBasicParsing

Write-Host "  OK - Scripts prontos" -ForegroundColor Green

# -- 2.4: Baixar referencias -------------------------------------------
Write-Host ">> Baixando documentacao de referencia..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "$REPO_RAW/references/metodologia-completa.md" -OutFile "$SKILL_DIR\references\metodologia-completa.md" -UseBasicParsing
Invoke-WebRequest -Uri "$REPO_RAW/references/fallbacks-e-falhas.md"   -OutFile "$SKILL_DIR\references\fallbacks-e-falhas.md"   -UseBasicParsing

Write-Host "  OK - Referencias baixadas" -ForegroundColor Green

# -- 2.5: Instalar dependencias npm ------------------------------------
Write-Host ">> Instalando dependencias da skill..." -ForegroundColor Yellow

$npmAvailable = Get-Command npm -ErrorAction SilentlyContinue

if ($npmAvailable) {
    Set-Location $SKILL_DIR
    npm install --silent 2>$null
    Write-Host "  OK - Dependencias instaladas (Playwright disponivel)" -ForegroundColor Green
} else {
    Write-Host "  npm nao disponivel — pulando. A skill funciona normalmente."
    Write-Host "  (Apenas funcoes avancadas ficarao desativadas)"
}
Write-Host ""

# ===============================================================
# FASE 3: CONFIGURAR TRIGGERS
# ===============================================================

Write-Host "-- FASE 3: Configurando ativacao automatica --" -ForegroundColor Cyan
Write-Host ""

Write-Host ">> Configurando triggers no Claude Code..." -ForegroundColor Yellow

# Criar CLAUDE.md se nao existir
if (-not (Test-Path $CLAUDE_MD)) {
    New-Item -ItemType File -Force -Path $CLAUDE_MD | Out-Null
}

# Adicionar secao de triggers apenas se ainda nao existir
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
    Write-Host "  OK - Triggers configurados" -ForegroundColor Green
} else {
    Write-Host "  OK - Triggers ja estavam configurados" -ForegroundColor Green
}
Write-Host ""

# ===============================================================
# CONCLUIDO
# ===============================================================

Write-Host "================================================" -ForegroundColor Green
Write-Host "                                                " -ForegroundColor Green
Write-Host "   Funnel Hacking instalado com sucesso!        " -ForegroundColor Green
Write-Host "                                                " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Como usar:"
Write-Host ""
Write-Host "  1. Abra o Claude Code (VS Code, terminal, ou app desktop)"
Write-Host "  2. Digite: /funnel-hacking"
Write-Host "  3. Ou escreva naturalmente, ex: ""descobrir concorrentes"""
Write-Host ""
Write-Host "  Duvidas? Fale com quem te enviou este instalador." -ForegroundColor Cyan
Write-Host ""
