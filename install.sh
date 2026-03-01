#!/bin/bash

# ============================================================
# Instalador da Skill: Funnel Hacking Agent
# Repositório: https://github.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill
# ============================================================

set -e

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

# ── PASSO 1: Criar pastas ───────────────────────────────────
echo -e "${AMARELO}▶ Criando pastas...${RESET}"
mkdir -p "$SKILL_DIR/scripts"
mkdir -p "$SKILL_DIR/references"
mkdir -p "$SKILL_DIR/assets"
mkdir -p "$HOME/.claude"
echo -e "${VERDE}  ✓ Pastas criadas${RESET}"

# ── PASSO 2: Baixar arquivos principais ────────────────────
echo -e "${AMARELO}▶ Baixando arquivos da skill...${RESET}"

curl -fsSL "$REPO_RAW/SKILL.md"       -o "$SKILL_DIR/SKILL.md"
curl -fsSL "$REPO_RAW/README.md"      -o "$SKILL_DIR/README.md"
curl -fsSL "$REPO_RAW/package.json"   -o "$SKILL_DIR/package.json"

echo -e "${VERDE}  ✓ Arquivos principais baixados${RESET}"

# ── PASSO 3: Baixar scripts ────────────────────────────────
echo -e "${AMARELO}▶ Baixando scripts...${RESET}"

curl -fsSL "$REPO_RAW/scripts/google-dork-funnel.sh" -o "$SKILL_DIR/scripts/google-dork-funnel.sh"
curl -fsSL "$REPO_RAW/scripts/download-vsl.sh"       -o "$SKILL_DIR/scripts/download-vsl.sh"
curl -fsSL "$REPO_RAW/scripts/funnel-crawler.js"     -o "$SKILL_DIR/scripts/funnel-crawler.js"
curl -fsSL "$REPO_RAW/scripts/screenshot-page.js"    -o "$SKILL_DIR/scripts/screenshot-page.js"

# Dar permissão de execução nos scripts shell
chmod +x "$SKILL_DIR/scripts/google-dork-funnel.sh"
chmod +x "$SKILL_DIR/scripts/download-vsl.sh"

echo -e "${VERDE}  ✓ Scripts prontos${RESET}"

# ── PASSO 4: Baixar referências ────────────────────────────
echo -e "${AMARELO}▶ Baixando documentação de referência...${RESET}"

curl -fsSL "$REPO_RAW/references/metodologia-completa.md" -o "$SKILL_DIR/references/metodologia-completa.md"
curl -fsSL "$REPO_RAW/references/fallbacks-e-falhas.md"   -o "$SKILL_DIR/references/fallbacks-e-falhas.md"

echo -e "${VERDE}  ✓ Referências baixadas${RESET}"

# ── PASSO 5: Instalar dependências Node.js (opcional) ──────
echo -e "${AMARELO}▶ Verificando Node.js...${RESET}"

if command -v npm &>/dev/null; then
    echo -e "  Node.js encontrado. Instalando dependências..."
    cd "$SKILL_DIR" && npm install --silent 2>/dev/null
    echo -e "${VERDE}  ✓ Dependências instaladas (Playwright disponível)${RESET}"
else
    echo -e "  Node.js não encontrado — tudo bem! A skill funciona normalmente."
    echo -e "  (Apenas o download de VSL bloqueada ficará desativado)"
fi

# ── PASSO 6: Configurar triggers no CLAUDE.md ──────────────
echo -e "${AMARELO}▶ Configurando ativação automática no Claude Code...${RESET}"

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

# ── CONCLUÍDO ───────────────────────────────────────────────
echo ""
echo -e "${VERDE}${NEGRITO}================================================${RESET}"
echo -e "${VERDE}${NEGRITO}   ✅ Funnel Hacking instalado com sucesso!     ${RESET}"
echo -e "${VERDE}${NEGRITO}================================================${RESET}"
echo ""
echo -e "  Como usar:"
echo -e "  ${NEGRITO}1.${RESET} Abra o Claude Code"
echo -e "  ${NEGRITO}2.${RESET} Digite: ${NEGRITO}/funnel-hacking${RESET}"
echo -e "  ${NEGRITO}3.${RESET} Ou escreva naturalmente, ex: ${NEGRITO}\"descobrir concorrentes\"${RESET}"
echo ""
