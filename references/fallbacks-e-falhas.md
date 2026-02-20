# Auditoria de Falhas e Solucoes Preventivas

Sistema de prevencao de falhas para o skill /funnel-hacking. 31 pontos de falha identificados em 7 categorias com solucoes preventivas para cada um.

---

## CATEGORIA 1: FALHAS DE FERRAMENTAS (WebFetch / WebSearch)

### F1: Site bloqueia WebFetch (Cloudflare, CAPTCHA, 403)
- **Probabilidade:** ALTA para SimilarWeb, BuiltWith, ViewDnsInfo, Instagram
- **Prevencao:** NUNCA depender exclusivamente de WebFetch para dados criticos
- **Solucao:**
  - Tentativa 1: WebFetch direto na URL
  - Tentativa 2: WebSearch "[dominio] + [dado que quero]"
  - Tentativa 3: WebSearch por cached version ou ferramentas alternativas
  - Tentativa 4: WebFetch em servico alternativo

### F2: Pagina usa JavaScript pesado (SPA/React) - HTML vazio
- **Probabilidade:** MEDIA-ALTA
- **Prevencao:** Nao depender do body HTML para dados criticos
- **Solucao:** Extrair dados de:
  - <meta property="og:title"> = headline
  - <meta property="og:description"> = descricao
  - <script> tags com pixel IDs, GTM IDs, URLs de API
  - <link> tags que revelam outras paginas
  - Se HTML realmente vazio: WebSearch "cache:[url]"

### F3: Redirects complexos nao seguidos
- **Probabilidade:** MEDIA
- **Solucao:** Se WebFetch retorna redirect:
  1. Extrair URL de destino
  2. WebFetch na nova URL
  3. Registrar AMBAS URLs (revela estrutura do funil)

### F4: robots.txt / sitemap.xml nao existem
- **Probabilidade:** ALTA para operacoes pequenas
- **Solucao:** Tentar TODAS as variacoes:
  - /robots.txt, /sitemap.xml, /sitemap_index.xml, /wp-sitemap.xml
  - /sitemap.gz, /post-sitemap.xml, /page-sitemap.xml
  - /?s= (busca interna WordPress)
  - Se nenhuma funciona: NAO e falha, seguir para outros metodos

### F5: WebSearch retorna resultados irrelevantes
- **Probabilidade:** MEDIA
- **Solucao:** Refinamento progressivo:
  - Busca 1: "[keyword] [nicho]" (ampla)
  - Busca 2: "[keyword] [nicho] [qualificador]" (ex: curso, produto, comprar)
  - Busca 3: "[keyword exacto]" entre aspas
  - Busca 4: combinar com site: operator
  - CRITERIO: resultado so entra se URL leva a pagina de produto/servico/oferta

### F6: Resultados regionais misturados (BR vs internacional)
- **Probabilidade:** ALTA
- **Solucao:**
  - Buscar primeiro em PT-BR, depois em EN
  - SEMPRE classificar como [BR] ou [INT]
  - Usuario pode filtrar depois

---

## CATEGORIA 2: FALHAS DE SUBAGENTES

### F7: Subagente falha silenciosamente (nao escreve output)
- **Probabilidade:** BAIXA-MEDIA
- **Prevencao CRITICA:**
  1. Apos cada lote, verificar se arquivo existe (Glob)
  2. Verificar se tem conteudo (Read primeiras 10 linhas)
  3. Se vazio/inexistente: RE-DISPARAR (max 2 retentativas)
  4. Se falhar 3x: registrar em _estado.md como FALHA e continuar

### F8: Subagente escreve dados incompletos (contexto estourou)
- **Probabilidade:** MEDIA para tarefas pesadas
- **Prevencao:** Instrucao: "Escreva cada achado IMEDIATAMENTE. Nunca acumule."

### F9: Dois subagentes tentam escrever no mesmo arquivo
- **Probabilidade:** ALTA se nao prevenida
- **REGRA ABSOLUTA:** Cada subagente escreve em arquivo PROPRIO
  - Subagente X escreve em arquivo-x.md
  - Subagente Y escreve em arquivo-y.md
  - Agente principal faz MERGE depois

### F10: Subagente interpreta tarefa errada
- **Probabilidade:** BAIXA se prompts claros
- **Prevencao:** Usar TEMPLATES EXATOS com queries especificas, nao instrucoes vagas

---

## CATEGORIA 3: FALHAS DE QUALIDADE DE DADOS

### F11: Duplicatas (mesmo concorrente encontrado multiplas vezes)
- **Probabilidade:** ALTISSIMA
- **Solucao - DEDUPLICACAO obrigatoria:**
  1. Normalizar URLs: remover www, trailing slash, lowercase
  2. Agrupar por dominio raiz
  3. Verificar se nomes diferentes apontam pro mesmo dominio
  4. Verificar se dominios diferentes usam mesmo pixel
  5. MERGE: manter entrada mais completa, adicionar aliases

### F12: Falso positivo (nao-concorrente na lista)
- **Probabilidade:** MEDIA
- **Criterio minimo:** Resultado deve ter pelo menos 2 sinais:
  - Pagina de vendas/oferta identificavel
  - Anuncios ativos
  - Presente em marketplace
  - Conteudo sobre o nicho
  - Se so 1 sinal: lista separada "candidato nao confirmado"

### F13: Falso negativo (concorrente importante nao encontrado)
- **Probabilidade:** MEDIA-BAIXA com multiplos metodos
- **Mitigacao:** No final, buscar: "maiores [nicho] brasil 2025/2026", "top [produto] [nicho]", "[nicho] lideres". Se nome aparece que NAO esta na lista, adicionar.

### F14: Dados desatualizados (concorrente ja parou)
- **Probabilidade:** MEDIA
- **CHECK DE FRESCOR:**
  1. WebFetch no dominio: retorna 200?
  2. Se 404/timeout: marcar POSSIVELMENTE INATIVO
  3. WebSearch "[marca] [ano atual]": atividade recente?
  4. Nao remover - marcar status e prioridade baixa

### F15: Confundir afiliado com concorrente
- **Probabilidade:** MEDIA
- **DETECTOR DE AFILIADO:**
  - URL de checkout aponta para dominio DIFERENTE do anuncio
  - URL contem ref=, aff=, hotmart.com/show/, parametros de afiliacao
  - Footer com "Produto hospedado em [plataforma]" sem marca propria
  - SE detectar: classificar como "AFILIADO de [produtor real]"

### F16: Mesmo CNPJ/dono operando multiplas marcas
- **Probabilidade:** ALTA no mercado digital BR
- **Acao:** Criar entrada "GRUPO: [nome]" com lista de todas as marcas
  - NAO e duplicata - e inteligencia: revela tamanho real da operacao

---

## CATEGORIA 4: FALHAS DE FERRAMENTAS EXTERNAS ESPECIFICAS

### F17: ViewDnsInfo bloqueia WebFetch
- **Probabilidade:** ALTA
- **Cadeia de fallback (7 tentativas):**
  1. WebFetch viewdns.info/reverseip/?host=[dominio]
  2. WebSearch "viewdns [dominio] reverse ip"
  3. WebSearch "[IP] hosted sites"
  4. WebFetch dnsdumpster.com
  5. WebSearch "securitytrails [dominio] subdomains"
  6. WebSearch "[dominio] related domains"
  7. Registrar "nao mapeavel" + compensar com Google Dorking e pixel tracking

### F18: SimilarWeb inacessivel
- **Probabilidade:** CERTEZA para WebFetch direto
- **REGRA:** NUNCA tentar WebFetch no SimilarWeb
- **Alternativas:**
  1. WebSearch "[dominio] traffic"
  2. WebSearch "[dominio] similarweb" (blogs que publicaram dados)
  3. WebSearch "[dominio] monthly visitors"
  4. WebSearch "[dominio] alexa rank"
  5. Estimar por sinais indiretos

### F19: Meta Ad Library nao acessivel
- **Probabilidade:** CERTEZA (app JS, nao API)
- **Compensar com:**
  1. WebSearch "[marca] facebook ad"
  2. Google Dork disclaimer Facebook
  3. WebFetch pagina → detectar Meta Pixel no HTML
  4. WebSearch "[marca] foreplay" ou "adspy"
  - LIMITACAO: nao ve criativos reais, confirma que anuncia e encontra landing pages

### F20: Instagram bloqueia WebFetch
- **Probabilidade:** ALTA
- **Cadeia:**
  1. WebSearch "[usuario] instagram bio"
  2. WebSearch "[usuario] instagram link"
  3. WebSearch "[marca] linktr.ee" ou "linkin.bio"
  4. Se encontrar link da bio → WebFetch nele

---

## CATEGORIA 5: FALHAS DE ESTADO E CONTINUIDADE

### F21: Estado corrompido ou sobrescrito
- **Prevencao:** _estado.md usa formato APPEND-ONLY com timestamps
  - Nunca sobrescrever, sempre adicionar nova linha
  - Ultima linha = estado atual

### F22: Prompt de retomada insuficiente
- **Prevencao:** Template FIXO com: objetivo ativo, ultima etapa, proximo passo, nicho, keywords, contagem de resultados

### F23: Continuidade entre objetivos
- **Prevencao:** Output AUTOCONTIDO por objetivo
  - Obj 1 gera _concorrentes.md → Obj 3 le como input
  - Nao depende de estado em memoria
  - Skill detecta automaticamente output anterior existente

---

## CATEGORIA 6: EDGE CASES

### F24: Nicho com menos de 20 concorrentes
- **Solucao:**
  1. Expandir para nichos ADJACENTES (marcar [NICHO ADJACENTE])
  2. Expandir para mercado internacional (marcar [INTERNACIONAL])
  3. Se ainda < 20: reportar honestamente como nicho com competicao limitada

### F25: Concorrente muito novo (< 30 dias)
- **Solucao:** Incluir buscas com filtro temporal: "[nicho] novo 2026", "[nicho] lancamento recente"

### F26: Paginas protegidas por senha
- **Aceitar limitacao.** O que PODE ser descoberto:
  - A URL da area de membros
  - O TIPO de plataforma (visivel na URL)
  - Indicios do conteudo (meta tags, og: description)
  - Registrar: "AREA DE MEMBROS DETECTADA: [URL] - plataforma: [X] - acesso: PROTEGIDO"

### F27: Concorrente opera apenas em redes sociais (sem site)
- **Solucao:** Classificar como "SOCIAL-ONLY", tentar WebSearch por mencoes/reviews/reclamacoes

### F28: Volume excessivo (nicho muito grande, 200+ resultados)
- **Solucao:**
  1. Priorizar por sinais de escala
  2. Validar apenas top 50 por score
  3. Reportar: "Encontrados X candidatos. Validados top 50."

---

## CATEGORIA 7: FALHAS DE OUTPUT

### F29: URLs quebradas no swipefile
- **Prevencao:** Salvar TAMBEM: data da coleta, titulo, descricao
  - Mesmo que URL quebre, conteudo-chave registrado
  - Incluir link Archive.org como backup

### F30: Mapa de funil incompleto
- **Prevencao - HONESTIDADE:** Mapa tem 2 zonas:
  - ZONA MAPEADA (alta confianca): paginas confirmadas
  - ZONA INFERIDA (media confianca): paginas que provavelmente existem baseado em padroes
  - Marcar: [CONFIRMADO] vs [INFERIDO]

### F31: Score de escala impreciso
- **Prevencao:** Score NUNCA e absoluto. E faixa com confianca:
  - Score 12/15 (alta confianca: 5+ fontes) = CONFIAVEL
  - Score 8/15 (media confianca: 3 fontes) = PROVAVEL
  - Score 4/15 (baixa confianca: 1-2 fontes) = POSSIVEL
  - Output inclui: score + nivel de confianca + fontes

---

## Resumo de Acoes por Tipo de Falha

| Tipo | Acao Padrao |
|------|-------------|
| WebFetch bloqueado | WebSearch como fallback imediato |
| Subagente sem output | Re-disparar (max 2x) |
| Dados duplicados | Deduplicacao por dominio + pixel |
| Dados desatualizados | Check de frescor (WebFetch 200?) |
| Nicho pequeno | Expandir para adjacentes + internacional |
| Volume excessivo | Priorizar top 50 por sinais de escala |
| Pagina protegida | Registrar URL + plataforma + marcar PROTEGIDO |
| Estado corrompido | APPEND-ONLY + timestamps |
