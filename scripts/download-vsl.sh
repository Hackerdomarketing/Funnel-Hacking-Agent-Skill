#!/bin/bash
# ============================================================
# download-vsl.sh — Captura de VSL bloqueada para Funnel Hacking
# Suporta: Vturb, ConvertAI, Bunny.net, HLS/M3U8, players customizados
# ============================================================
#
# USO:
#   ./download-vsl.sh <URL_DA_PAGINA> [nome-do-arquivo]
#   ./download-vsl.sh <URL_M3U8_DIRETA> [nome-do-arquivo]
#
# EXEMPLOS:
#   ./download-vsl.sh https://exemplo.com/vsl               # Detecta automaticamente
#   ./download-vsl.sh https://exemplo.com/vsl minha-vsl     # Nome customizado
#   ./download-vsl.sh "https://cdn.vturb.com.br/.../index.m3u8" vsl-concorrente
#
# METODOS (em ordem de tentativa):
#   1. yt-dlp direto na URL da pagina (detecta Vturb, Bunny, Wistia, Vimeo, etc.)
#   2. yt-dlp com cookies do Chrome (para conteudo autenticado)
#   3. yt-dlp com user-agent de browser
#   4. ffmpeg direta em URL m3u8 (se URL passada for m3u8)
#   5. Instrucoes para extracao manual via DevTools
# ============================================================

set -e

# ─── Cores ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Argumentos ──────────────────────────────────────────────
URL="${1}"
NOME="${2:-vsl-$(date +%Y%m%d-%H%M%S)}"
OUTPUT_DIR="./vsls-capturados"

if [ -z "$URL" ]; then
    echo -e "${RED}ERRO: URL nao fornecida.${NC}"
    echo ""
    echo "Uso: $0 <URL_DA_PAGINA_OU_M3U8> [nome-do-arquivo]"
    echo ""
    echo "Exemplos:"
    echo "  $0 https://exemplo.com.br/vsl"
    echo "  $0 https://cdn.vturb.com.br/videos/abc123/index.m3u8 concorrente-x"
    exit 1
fi

# ─── Helpers ─────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_error()   { echo -e "${RED}[ERRO]${NC} $1"; }
log_section() { echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}\n"; }

# ─── Verificar dependencias ───────────────────────────────────
check_deps() {
    local missing=0

    if ! command -v yt-dlp &>/dev/null; then
        log_error "yt-dlp nao encontrado. Instale com: brew install yt-dlp"
        missing=1
    fi

    if ! command -v ffmpeg &>/dev/null; then
        log_error "ffmpeg nao encontrado. Instale com: brew install ffmpeg"
        missing=1
    fi

    [ $missing -eq 1 ] && exit 1
    log_ok "Dependencias OK (yt-dlp $(yt-dlp --version), ffmpeg disponivel)"
}

# ─── Criar pasta de output ────────────────────────────────────
setup_output() {
    mkdir -p "$OUTPUT_DIR"
    log_info "Output: $OUTPUT_DIR/"
}

# ─── Detectar se URL e M3U8 direto ───────────────────────────
is_m3u8_url() {
    echo "$1" | grep -qiE "\.(m3u8|m3u)(\?|$)"
}

# ─── Metodo 1: yt-dlp automatico ─────────────────────────────
metodo_ytdlp_auto() {
    log_section "Metodo 1: yt-dlp — Deteccao automatica"
    log_info "Tentando extrair video automaticamente de: $URL"
    log_info "Suporta: Vturb, Bunny.net, Wistia, Vimeo, YouTube, players HLS customizados"

    # Primeiro, listar formatos disponíveis
    log_info "Verificando formatos disponíveis..."
    if yt-dlp --list-formats "$URL" 2>/dev/null | head -20; then
        log_ok "Formatos detectados. Baixando melhor qualidade..."
        if yt-dlp \
            --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best" \
            --merge-output-format mp4 \
            --output "$OUTPUT_DIR/${NOME}.%(ext)s" \
            --no-playlist \
            --no-warnings \
            "$URL"; then
            log_ok "Download concluido: $OUTPUT_DIR/${NOME}.mp4"
            return 0
        fi
    fi

    log_warn "Metodo 1 falhou — tentando proximo..."
    return 1
}

# ─── Metodo 2: yt-dlp com User-Agent de browser real ─────────
metodo_ytdlp_browser() {
    log_section "Metodo 2: yt-dlp — User-Agent de browser"
    log_info "Simulando navegador para bypass de deteccao de bot..."

    if yt-dlp \
        --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" \
        --add-header "Referer:$URL" \
        --add-header "Accept-Language:pt-BR,pt;q=0.9,en;q=0.8" \
        --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best" \
        --merge-output-format mp4 \
        --output "$OUTPUT_DIR/${NOME}-m2.%(ext)s" \
        --no-playlist \
        "$URL"; then
        log_ok "Download concluido: $OUTPUT_DIR/${NOME}-m2.mp4"
        return 0
    fi

    log_warn "Metodo 2 falhou — tentando proximo..."
    return 1
}

# ─── Metodo 3: yt-dlp com cookies do Chrome ──────────────────
metodo_ytdlp_cookies() {
    log_section "Metodo 3: yt-dlp — Cookies do Chrome"
    log_info "Usando cookies do Chrome para conteudo autenticado..."
    log_warn "Chrome precisa estar FECHADO para este metodo funcionar"

    if yt-dlp \
        --cookies-from-browser chrome \
        --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best" \
        --merge-output-format mp4 \
        --output "$OUTPUT_DIR/${NOME}-m3.%(ext)s" \
        --no-playlist \
        "$URL" 2>/dev/null; then
        log_ok "Download concluido: $OUTPUT_DIR/${NOME}-m3.mp4"
        return 0
    fi

    log_warn "Metodo 3 falhou — tentando proximo..."
    return 1
}

# ─── Metodo 4: ffmpeg direto em M3U8 ─────────────────────────
metodo_ffmpeg_m3u8() {
    local M3U8_URL="${1:-$URL}"
    log_section "Metodo 4: ffmpeg — Stream HLS/M3U8 direto"
    log_info "URL M3U8: $M3U8_URL"

    OUTPUT_FILE="$OUTPUT_DIR/${NOME}-m4.mp4"

    # Tenta download normal primeiro
    log_info "Tentativa 4a: Stream HLS padrao..."
    if ffmpeg \
        -protocol_whitelist file,http,https,tcp,tls,crypto \
        -user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        -i "$M3U8_URL" \
        -c copy \
        -bsf:a aac_adtstoasc \
        "$OUTPUT_FILE" -y 2>/dev/null; then
        log_ok "Download concluido: $OUTPUT_FILE"
        return 0
    fi

    # Tenta com referer
    log_info "Tentativa 4b: Com Referer header..."
    if ffmpeg \
        -protocol_whitelist file,http,https,tcp,tls,crypto \
        -headers "Referer: $URL\r\nUser-Agent: Mozilla/5.0\r\n" \
        -i "$M3U8_URL" \
        -c copy \
        "$OUTPUT_FILE" -y 2>/dev/null; then
        log_ok "Download concluido: $OUTPUT_FILE"
        return 0
    fi

    log_warn "Metodo 4 falhou — tentando proximo..."
    return 1
}

# ─── Instrucoes manuais (fallback final) ─────────────────────
instrucoes_manuais() {
    log_section "Metodo 5: Extracao manual via DevTools (fallback)"
    echo ""
    echo -e "${BOLD}Passo a passo para capturar M3U8 manualmente:${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} Abra o Chrome/Firefox com DevTools (F12)"
    echo -e "${YELLOW}2.${NC} Va na aba ${BOLD}Network${NC}"
    echo -e "${YELLOW}3.${NC} No campo de filtro, digite: ${BOLD}m3u8${NC}"
    echo -e "${YELLOW}4.${NC} Abra a pagina: ${BOLD}$URL${NC}"
    echo -e "${YELLOW}5.${NC} DE PLAY no video"
    echo -e "${YELLOW}6.${NC} Copie a URL da requisicao m3u8 que aparecer"
    echo ""
    echo -e "${BOLD}Depois execute:${NC}"
    echo -e "  ${GREEN}$0 \"<URL_M3U8_COPIADA>\" $NOME${NC}"
    echo ""
    echo -e "${BOLD}OU use diretamente com ffmpeg:${NC}"
    echo -e "  ${GREEN}ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i \"<URL_M3U8>\" -c copy $OUTPUT_DIR/${NOME}.mp4${NC}"
    echo ""
    echo -e "${BOLD}Extensoes de navegador que capturam M3U8 automaticamente:${NC}"
    echo -e "  ${CYAN}Chrome:${NC} HLS Downloader — https://chromewebstore.google.com/detail/hls-downloader/hkbifmjmkohpemgdkknlbgmnpocooogp"
    echo -e "  ${CYAN}Firefox:${NC} Live Stream Downloader — https://addons.mozilla.org/en-US/firefox/addon/live-stream-downloader/"
    echo -e "  ${CYAN}Chrome:${NC} Stream Recorder — https://www.hlsloader.com/"
    echo ""
    echo -e "${BOLD}Para streams Vturb especificamente:${NC}"
    echo -e "  O Vturb serve via CDN (geralmente Bunny.net ou CloudFront)"
    echo -e "  A URL m3u8 normalmente tem formato:"
    echo -e "  ${CYAN}https://[id].vturb.com.br/videos/[hash]/[qualidade]/index.m3u8${NC}"
    echo -e "  ${CYAN}https://cdn-[id].bunnycdn.com/[path]/index.m3u8${NC}"
    echo ""
    echo -e "${BOLD}Para ConvertAI:${NC}"
    echo -e "  URL m3u8 normalmente: ${CYAN}https://[cdn].convertai.com.br/[hash]/playlist.m3u8${NC}"
}

# ─── Extrair URL M3U8 de pagina via yt-dlp ───────────────────
extrair_url_stream() {
    log_section "Extraindo URL do stream (para uso manual)"
    log_info "Tentando extrair URL direta do video..."

    if STREAM_URL=$(yt-dlp -g "$URL" 2>/dev/null | head -1); then
        if [ -n "$STREAM_URL" ]; then
            log_ok "URL do stream encontrada:"
            echo -e "  ${GREEN}$STREAM_URL${NC}"
            echo ""
            log_info "Voce pode usar esta URL diretamente com ffmpeg ou salvar em outro dispositivo"
            return 0
        fi
    fi

    log_warn "Nao foi possivel extrair URL do stream automaticamente"
    return 1
}

# ─── MAIN ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║        DOWNLOAD-VSL — Funnel Hacking Toolkit        ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
log_info "URL alvo: $URL"
log_info "Nome do arquivo: $NOME"
echo ""

check_deps
setup_output

# Se URL ja e M3U8 direto, pular para ffmpeg
if is_m3u8_url "$URL"; then
    log_info "URL M3U8 detectada — usando ffmpeg direto"
    metodo_ffmpeg_m3u8 "$URL" && exit 0
    instrucoes_manuais
    exit 1
fi

# Sequencia de metodos para URL de pagina
SUCCESS=0

metodo_ytdlp_auto    && SUCCESS=1
[ $SUCCESS -eq 0 ] && metodo_ytdlp_browser && SUCCESS=1
[ $SUCCESS -eq 0 ] && metodo_ytdlp_cookies && SUCCESS=1

# Tentar extrair URL do stream como bonus
if [ $SUCCESS -eq 0 ]; then
    extrair_url_stream
    instrucoes_manuais
    exit 1
fi

echo ""
log_ok "VSL capturada com sucesso em: $OUTPUT_DIR/"
echo -e "${BOLD}Dica:${NC} Use vlc ou QuickTime para assistir o video offline"
