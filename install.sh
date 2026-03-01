#!/bin/bash

# ============================================================
# Instalador da Skill: Funnel Hacking Agent
# Repositório: https://github.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill
#
# Detecta e instala automaticamente tudo que for necessário:
# Homebrew, Node.js, Claude Code CLI, e a skill completa.
# ============================================================

# Cores para mensagens
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
VERMELHO='\033[0;31m'
RESET='\033[0m'
NEGRITO='\033[1m'

REPO_RAW="https://raw.githubusercontent.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill/main"
SKILL_DIR="$HOME/.claude/skills/funnel-hacking"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo ""
echo -e "${AZUL}${NEGRITO}================================================${RESET}"
echo -e "${AZUL}${NEGRITO}   Instalando: Funnel Hacking Agent Skill       ${RESET}"
echo -e "${AZUL}${NEGRITO}================================================${RESET}"
echo ""
echo -e "  Vou verificar tudo que precisa e instalar"
echo -e "  automaticamente. Pode demorar alguns minutos"
echo -e "  na primeira vez."
echo ""

# ═══════════════════════════════════════════════════════════
# FASE 1: VERIFICAR E INSTALAR PRÉ-REQUISITOS
# ═══════════════════════════════════════════════════════════

echo -e "${AZUL}${NEGRITO}── FASE 1: Verificando pré-requisitos ──${RESET}"
echo ""

# ── 1.1: Homebrew (gerenciador de pacotes do Mac) ──────────
echo -e "${AMARELO}▶ Verificando Homebrew...${RESET}"

if command -v brew &>/dev/null; then
    echo -e "${VERDE}  ✓ Homebrew já está instalado${RESET}"
else
    echo -e "  Homebrew não encontrado. Instalando..."
    echo -e "  (O Mac pode pedir sua senha de usuário — é normal)"
    echo ""
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Adicionar Homebrew ao PATH para Apple Silicon (M1/M2/M3/M4)
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Garantir que funcione em futuras sessões do terminal
        if [ -f "$HOME/.zprofile" ]; then
            grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile" 2>/dev/null || \
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        else
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
    fi

    if command -v brew &>/dev/null; then
        echo -e "${VERDE}  ✓ Homebrew instalado com sucesso${RESET}"
    else
        echo -e "${VERMELHO}  ✗ Não consegui instalar o Homebrew. Mas vou tentar continuar.${RESET}"
    fi
fi
echo ""

# ── 1.2: Node.js ──────────────────────────────────────────
echo -e "${AMARELO}▶ Verificando Node.js...${RESET}"

if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${VERDE}  ✓ Node.js já está instalado (versão $NODE_VERSION)${RESET}"
else
    echo -e "  Node.js não encontrado. Instalando..."
    if command -v brew &>/dev/null; then
        brew install node 2>/dev/null
        if command -v node &>/dev/null; then
            echo -e "${VERDE}  ✓ Node.js instalado com sucesso${RESET}"
        else
            echo -e "${VERMELHO}  ✗ Não consegui instalar o Node.js.${RESET}"
        fi
    else
        echo -e "${AMARELO}  Sem Homebrew disponível. Pulando instalação do Node.js.${RESET}"
        echo -e "  (Funções avançadas como download de VSL ficarão desativadas)${RESET}"
    fi
fi
echo ""

# ── 1.3: Claude Code CLI ─────────────────────────────────
echo -e "${AMARELO}▶ Verificando Claude Code...${RESET}"

if [ -d "$HOME/.claude" ]; then
    echo -e "${VERDE}  ✓ Claude Code já está configurado${RESET}"
else
    echo -e "  Pasta do Claude Code não encontrada."

    if command -v claude &>/dev/null; then
        echo -e "${VERDE}  ✓ Claude Code CLI encontrado. Criando pasta...${RESET}"
        mkdir -p "$HOME/.claude"
    elif command -v npm &>/dev/null; then
        echo -e "  Instalando Claude Code via terminal..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null
        if command -v claude &>/dev/null; then
            echo -e "${VERDE}  ✓ Claude Code CLI instalado com sucesso${RESET}"
            mkdir -p "$HOME/.claude"
        else
            echo -e "${AMARELO}  Não consegui instalar o CLI, mas vou criar a pasta.${RESET}"
            echo -e "  Você pode usar o Claude Code pelo app desktop ou VS Code.${RESET}"
            mkdir -p "$HOME/.claude"
        fi
    else
        echo -e "${AMARELO}  Criando a pasta do Claude Code...${RESET}"
        echo -e "  Quando você abrir o Claude Code pela primeira vez,"
        echo -e "  ele vai reconhecer a skill automaticamente.${RESET}"
        mkdir -p "$HOME/.claude"
    fi
fi
echo ""

echo -e "${VERDE}${NEGRITO}── Pré-requisitos prontos! ──${RESET}"
echo ""

# ═══════════════════════════════════════════════════════════
# FASE 2: INSTALAR A SKILL
# ═══════════════════════════════════════════════════════════

echo -e "${AZUL}${NEGRITO}── FASE 2: Instalando a skill ──${RESET}"
echo ""

# ── 2.1: Criar pastas ────────────────────────────────────
echo -e "${AMARELO}▶ Criando pastas da skill...${RESET}"
mkdir -p "$SKILL_DIR/scripts"
mkdir -p "$SKILL_DIR/references"
mkdir -p "$SKILL_DIR/assets"
echo -e "${VERDE}  ✓ Pastas criadas${RESET}"

# ── 2.2: Baixar arquivos principais ──────────────────────
echo -e "${AMARELO}▶ Baixando arquivos da skill...${RESET}"

curl -fsSL "$REPO_RAW/SKILL.md"       -o "$SKILL_DIR/SKILL.md"
curl -fsSL "$REPO_RAW/README.md"      -o "$SKILL_DIR/README.md"
curl -fsSL "$REPO_RAW/package.json"   -o "$SKILL_DIR/package.json"

echo -e "${VERDE}  ✓ Arquivos principais baixados${RESET}"

# ── 2.3: Baixar scripts ──────────────────────────────────
echo -e "${AMARELO}▶ Baixando scripts de automação...${RESET}"

curl -fsSL "$REPO_RAW/scripts/google-dork-funnel.sh" -o "$SKILL_DIR/scripts/google-dork-funnel.sh"
curl -fsSL "$REPO_RAW/scripts/download-vsl.sh"       -o "$SKILL_DIR/scripts/download-vsl.sh"
curl -fsSL "$REPO_RAW/scripts/funnel-crawler.js"     -o "$SKILL_DIR/scripts/funnel-crawler.js"
curl -fsSL "$REPO_RAW/scripts/screenshot-page.js"    -o "$SKILL_DIR/scripts/screenshot-page.js"

chmod +x "$SKILL_DIR/scripts/google-dork-funnel.sh"
chmod +x "$SKILL_DIR/scripts/download-vsl.sh"

echo -e "${VERDE}  ✓ Scripts prontos${RESET}"

# ── 2.4: Baixar referências ──────────────────────────────
echo -e "${AMARELO}▶ Baixando documentação de referência...${RESET}"

curl -fsSL "$REPO_RAW/references/metodologia-completa.md" -o "$SKILL_DIR/references/metodologia-completa.md"
curl -fsSL "$REPO_RAW/references/fallbacks-e-falhas.md"   -o "$SKILL_DIR/references/fallbacks-e-falhas.md"

echo -e "${VERDE}  ✓ Referências baixadas${RESET}"

# ── 2.5: Instalar dependências npm ───────────────────────
echo -e "${AMARELO}▶ Instalando dependências da skill...${RESET}"

if command -v npm &>/dev/null; then
    cd "$SKILL_DIR" && npm install --silent 2>/dev/null
    echo -e "${VERDE}  ✓ Dependências instaladas (Playwright disponível)${RESET}"
else
    echo -e "  npm não disponível — pulando. A skill funciona normalmente."
    echo -e "  (Apenas funções avançadas ficarão desativadas)"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# FASE 3: CONFIGURAR TRIGGERS
# ═══════════════════════════════════════════════════════════

echo -e "${AZUL}${NEGRITO}── FASE 3: Configurando ativação automática ──${RESET}"
echo ""

echo -e "${AMARELO}▶ Configurando triggers no Claude Code...${RESET}"

# Criar CLAUDE.md se não existir
if [ ! -f "$CLAUDE_MD" ]; then
    touch "$CLAUDE_MD"
fi

# Adicionar seção de triggers apenas se ainda não existir
if ! grep -q "funnel-hacking" "$CLAUDE_MD" 2>/dev/null; then
    cat >> "$CLAUDE_MD" << 'TRIGGER_BLOCK'


## FUNNEL HACKING

Quando o usuario usar qualquer uma destas frases, ative a skill `funnel-hacking`:

**Triggers de ativacao:**
- "funnel hacking", "ative o funnel hacking", "hacking de funil"
- "concorrentes", "descobrir concorrentes", "mapear concorrentes"
- "ofertas escaladas", "quem esta escalado"
- "mapear funil", "funil completo", "infiltrar funil"
- "baixar VSL", "capturar VSL", "VSL bloqueada"
- "buscar material", "buscar PDF", "baixar PDF", "encontrar livro"

**REGRA CRITICA:** SEMPRE usar a skill `funnel-hacking` quando o usuario pedir.
TRIGGER_BLOCK
    echo -e "${VERDE}  ✓ Triggers configurados${RESET}"
else
    echo -e "${VERDE}  ✓ Triggers já estavam configurados${RESET}"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# CONCLUÍDO
# ═══════════════════════════════════════════════════════════

echo -e "${VERDE}${NEGRITO}================================================${RESET}"
echo -e "${VERDE}${NEGRITO}                                                ${RESET}"
echo -e "${VERDE}${NEGRITO}   ✅ Funnel Hacking instalado com sucesso!     ${RESET}"
echo -e "${VERDE}${NEGRITO}                                                ${RESET}"
echo -e "${VERDE}${NEGRITO}================================================${RESET}"
echo ""
echo -e "  ${NEGRITO}Como usar:${RESET}"
echo -e ""
echo -e "  ${NEGRITO}1.${RESET} Abra o Claude Code (VS Code, terminal, ou app desktop)"
echo -e "  ${NEGRITO}2.${RESET} Digite: ${NEGRITO}/funnel-hacking${RESET}"
echo -e "  ${NEGRITO}3.${RESET} Ou escreva naturalmente, ex: ${NEGRITO}\"descobrir concorrentes\"${RESET}"
echo ""
echo -e "  ${AZUL}Dúvidas? Fale com quem te enviou este instalador.${RESET}"
echo ""
