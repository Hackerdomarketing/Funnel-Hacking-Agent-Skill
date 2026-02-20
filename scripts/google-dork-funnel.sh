#!/bin/bash

# google-dork-funnel.sh — Gerador de queries Google Dorking para Funnel Hacking
# Uso: ./google-dork-funnel.sh <dominio> [keyword]
# Exemplo: ./google-dork-funnel.sh laricolares.com "sobrancelha"

# Validate input
if [ -z "$1" ]; then
    echo "Uso: $0 <dominio> [keyword]"
    echo "Exemplo: $0 exemplo.com.br \"seu nicho\""
    exit 1
fi

DOMAIN="$1"
KEYWORD="${2:-}"
# Remove protocol and www if present
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||' | sed 's|www\.||' | sed 's|/$||')

echo "============================================"
echo "GOOGLE DORKING — FUNNEL HACKING"
echo "Dominio: $DOMAIN"
[ -n "$KEYWORD" ] && echo "Keyword: $KEYWORD"
echo "============================================"
echo ""

# Section 1: All indexed pages
echo "=== PAGINAS INDEXADAS ==="
echo "site:$DOMAIN"
echo ""

# Section 2: Funnel-specific pages (inurl: searches)
echo "=== PAGINAS DE FUNIL (inurl:) ==="
for term in upsell downsell obrigado checkout oto order-bump thankyou members especial vip webinar aula upgrade oferta login register promo trial curso plano assinatura; do
    echo "site:$DOMAIN inurl:$term"
done
echo ""

# Section 3: Subdomains
echo "=== SUBDOMINIOS ==="
echo "site:*.$DOMAIN"
echo ""

# Section 4: File types that might reveal structure
echo "=== ARQUIVOS ESPECIAIS ==="
echo "site:$DOMAIN filetype:pdf"
echo "site:$DOMAIN filetype:xml"
echo "site:$DOMAIN filetype:txt"
echo ""

# Section 5: Direct URLs to try (not Google queries, but direct access)
echo "=== URLs PARA ACESSAR DIRETAMENTE ==="
echo "https://$DOMAIN/robots.txt"
echo "https://$DOMAIN/sitemap.xml"
echo "https://$DOMAIN/wp-sitemap.xml"
echo "https://$DOMAIN/sitemap_index.xml"
echo "https://$DOMAIN/post-sitemap.xml"
echo "https://$DOMAIN/page-sitemap.xml"
echo "https://www.$DOMAIN/robots.txt"
echo "https://www.$DOMAIN/sitemap.xml"
echo ""

# Section 6: Reverse engineering tools
echo "=== FERRAMENTAS DE ESPIONAGEM ==="
echo "https://viewdns.info/reverseip/?host=$DOMAIN"
echo "https://web.archive.org/web/*/$DOMAIN"
echo "https://dnsdumpster.com/ (buscar: $DOMAIN)"
echo ""

# Section 7: Social presence
echo "=== PRESENCA SOCIAL ==="
echo "\"$DOMAIN\" instagram"
echo "\"$DOMAIN\" youtube"
echo "\"$DOMAIN\" tiktok"
echo "\"$DOMAIN\" linkedin"
echo "\"$DOMAIN\" facebook"
echo ""

# Section 8: Ads and scale evidence
echo "=== EVIDENCIA DE ADS/ESCALA ==="
echo "\"$DOMAIN\" ads"
echo "\"$DOMAIN\" facebook ads library"
echo "\"$DOMAIN\" google ads"
echo "\"$DOMAIN\" \"sponsored\" OR \"patrocinado\""
echo "\"$DOMAIN\" google ads transparency"
echo "site:reclameaqui.com.br \"${DOMAIN%%.*}\""
echo ""

# Section 9: Traffic and analytics
echo "=== TRAFEGO E ANALYTICS ==="
echo "\"$DOMAIN\" traffic"
echo "\"$DOMAIN\" similarweb"
echo "\"$DOMAIN\" monthly visitors"
echo "\"$DOMAIN\" alexa rank"
echo ""

# Section 10: WHOIS and ownership
echo "=== PROPRIEDADE E WHOIS ==="
echo "\"$DOMAIN\" whois"
echo "\"$DOMAIN\" registro.br"
echo "\"$DOMAIN\" cnpj"
echo ""

# Section 11: Keyword-specific (if keyword provided)
if [ -n "$KEYWORD" ]; then
    echo "=== QUERIES COM KEYWORD: $KEYWORD ==="
    echo "intext:\"This site is not a part of the Facebook\" intext:$KEYWORD"
    echo "intext:\"Este site nao faz parte do Facebook\" intext:$KEYWORD"
    echo "site:pay.kiwify.com.br $KEYWORD"
    echo "site:go.hotmart.com $KEYWORD"
    echo "site:pay.hotmart.com $KEYWORD"
    echo "site:app.monetizze.com.br $KEYWORD"
    echo "site:sun.eduzz.com $KEYWORD"
    echo "\"$KEYWORD\" facebook ad"
    echo "\"$KEYWORD\" review youtube"
    echo "\"$KEYWORD\" curso"
    echo "\"$KEYWORD\" produto digital"
    echo "site:reclameaqui.com.br \"$KEYWORD\""
    echo "site:hotmart.com $KEYWORD"
    echo "site:kiwify.com.br $KEYWORD"
    echo ""
fi

# Section 12: Platform-specific URL patterns to try
echo "=== PADROES DE URL POR PLATAFORMA (tentar acessar) ==="
echo "--- Se ClickFunnels ---"
echo "https://$DOMAIN/upsell"
echo "https://$DOMAIN/oto"
echo "https://$DOMAIN/order-confirmation"
echo "https://$DOMAIN/members"
echo "https://$DOMAIN/webinar"
echo "--- Se WordPress ---"
echo "https://$DOMAIN/minha-conta"
echo "https://$DOMAIN/checkout"
echo "https://$DOMAIN/obrigado"
echo "https://$DOMAIN/?s="
echo "--- Variacoes comuns ---"
echo "https://$DOMAIN/pagina-vendas-2"
echo "https://$DOMAIN/pagina-vendas-b"
echo "https://$DOMAIN/lp-v2"
echo "https://$DOMAIN/lp-a"
echo "https://$DOMAIN/lp-b"
echo ""

echo "============================================"
echo "Total de queries geradas."
echo "Cole cada query no Google para executar."
echo "============================================"
