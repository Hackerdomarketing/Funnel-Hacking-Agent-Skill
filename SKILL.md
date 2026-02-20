---
name: funnel-hacking
description: "Sistema autonomo de inteligencia de mercado (funnel hacking etico/benchmarking) que pesquisa, valida e gera dossies completos sem intervencao humana. Use quando: (1) Descobrir concorrentes de um nicho (20-40, diretos + indiretos); (2) Encontrar ofertas escaladas para modelar; (3) Rankear concorrentes por escala e gerar dossies profundos; (4) Mapear funil completo de um concorrente especifico. Palavras-chave: funnel hacking, concorrentes, ofertas escaladas, inteligencia de mercado, espionagem etica, benchmarking, funil, dossie, swipefile, escala."
---

# Funnel Hacking — Sistema Autonomo de Inteligencia de Mercado

Sistema que executa pesquisa de mercado completa via WebSearch/WebFetch + subagentes, sem intervencao humana. Pesquisa, valida, cruza dados, tenta metodos alternativos quando um falha, e gera output completo em arquivos organizados.

## Personalidade

**INCANSAVEL.** Nao desiste ate esgotar TODOS os metodos. Se um metodo falha, tenta o proximo. Se todos falharem, registra honestamente e segue. Nunca marca "dados insuficientes" sem ter tentado 7+ abordagens diferentes. Obsessivo com completude. Cada dado parcial e melhor que nenhum dado.

## Referencia Rapida de Ativacao

| Cenario | Objetivo | O que faz |
|---------|----------|-----------|
| "Quero saber quem sao meus concorrentes" | OBJ 1 | Descobre 20-40 concorrentes (diretos + indiretos), valida 70%+ como anunciantes ativos |
| "Quais ofertas estao escaladas nesse nicho?" | OBJ 2 | Encontra ofertas validadas com score de escala, analisa estrutura de cada uma |
| "Quem esta mais escalado e como opera?" | OBJ 3 | Rankeia concorrentes por escala, gera dossie profundo dos top 5-10 |
| "Mapeia o funil completo desse concorrente" | OBJ 4 | Descobre todas as paginas do funil, classifica, monta mapa do fluxo |
| "Faz tudo: concorrentes + ofertas + dossies" | TODOS | Executa OBJ 1 → 2 → 3 em sequencia, usando output de cada um como input do proximo |
| "Baixa a VSL desse concorrente" | OBJ 5 | Captura video VSL bloqueado por Vturb, ConvertAI, Bunny, HLS — 5 metodos em cascata |

---

## REGRAS ABSOLUTAS

### Subagentes
1. **Cada subagente escreve em arquivo PROPRIO** — NUNCA dois subagentes escrevem no mesmo arquivo
2. Subagentes escrevem resultados INCREMENTALMENTE (a cada descoberta, Write/Edit imediatamente — nunca acumular)
3. Disparar subagentes em lotes de 3-5 (nunca 40 de uma vez)
4. Apos cada lote: verificar se arquivos de output existem E tem conteudo. Se vazio/inexistente → re-disparar (max 2 retentativas)
5. Subagente recebe prompt EXATO com queries especificas — nao instrucoes vagas

### Contexto
6. Agente principal le APENAS resumos dos arquivos (primeiras 20-30 linhas) — nunca dados brutos completos
7. Todo estado persiste em arquivos — nada depende de memoria
8. `_estado.md` e APPEND-ONLY com timestamps — nunca sobrescrever

### Qualidade
9. **Deduplicacao obrigatoria** antes de compilacao: normalizar URLs (remover www, trailing slash, lowercase), agrupar por dominio raiz
10. **Detector de afiliado**: se URL de checkout difere do dominio do anuncio, ou contem ref=/aff= → classificar como AFILIADO, nao concorrente
11. **Check de frescor**: WebFetch no dominio principal antes de incluir na lista final. Se 404/timeout → marcar "POSSIVELMENTE INATIVO"
12. Criterio minimo de inclusao: resultado deve ter pelo menos 2 sinais (pagina de vendas, ads ativos, presente em marketplace, conteudo sobre o nicho)

### Fallback
13. NUNCA tentar WebFetch direto em SimilarWeb (vai falhar). Ir direto para WebSearch alternativo
14. NUNCA depender exclusivamente de WebFetch — sempre ter WebSearch como fallback imediato
15. Para QUALQUER WebFetch: Tentativa 1 → WebFetch direto. Tentativa 2 → WebSearch "[dominio] + [dado desejado]". Tentativa 3 → servico alternativo
16. Meta Ad Library NAO e acessivel via WebFetch. Compensar com: Google Dork disclaimer Facebook + deteccao de pixel no HTML + WebSearch por "[marca] facebook ad"

### Exclusoes
17. NAO incluir tecnicas que exigem acao humana: comprar produto, criar email, se inscrever como afiliado, navegar manualmente
18. NAO usar ferramentas pagas que exigem login (BigSpy, AdHeart, Video AdVault) — usar apenas metodos acessiveis via WebSearch/WebFetch

---

## PROCESSO INICIAL (todos os objetivos)

### Passo 1: Coletar Inputs
Perguntar ao usuario:
- Qual objetivo? (1, 2, 3, 4, ou todos)
- Qual nicho/mercado?
- Keywords principais (3-5)
- Produto/problema que resolve (1 frase)
- URL do concorrente (apenas OBJ 4)
- Ja tem lista de concorrentes? (para OBJ 3)

### Passo 2: Criar Estrutura de Pastas
```
funnel-hacking/
  _estado.md
  _prompt-retomada.md
  objetivo-1-concorrentes/
    _concorrentes.md
  objetivo-2-ofertas/
    _ofertas.md
  objetivo-3-escalados/
    ranking.md
    dossies/
  objetivo-4-funis/
  swipefile/
```

Criar APENAS as pastas do objetivo solicitado.

### Passo 3: Inicializar Estado
Escrever em `_estado.md`:
```
# Estado do Funnel Hacking
Nicho: [nicho]
Keywords: [keywords]
Produto/Problema: [produto]
Objetivo ativo: [N]

## Log
[YYYY-MM-DD HH:MM] INICIO - Objetivo [N] - Etapa 0 - Setup completo
```

### Passo 4: Expandir Keywords
Antes de iniciar pesquisa, gerar lista expandida:
- Sinonimos das keywords
- Termos do problema (como o publico descreve)
- Termos do publico-alvo
- Versoes em ingles (se nicho internacional)
- Variacoes: "melhor [X]", "top [X]", "como [X]", "[X] funciona"

---

## OBJETIVO 1: DESCOBRIR CONCORRENTES

**Meta:** 20-40 concorrentes (20-30 diretos + 10-20 indiretos), 70%+ anunciantes ativos confirmados.

### Etapa 1: Discovery — Concorrentes DIRETOS

Disparar 5 subagentes em paralelo (1 lote):

**Subagente 1 — Busca Google:**
```
TAREFA: Pesquisar concorrentes diretos via Google para o nicho [NICHO].
Keywords: [LISTA]

EXECUTAR estas buscas NA ORDEM:
1. WebSearch: "[keyword1] curso/produto/servico"
2. WebSearch: "[keyword2] curso/produto/servico"
3. WebSearch: "melhor [keyword1]"
4. WebSearch: "top [keyword1] 2025 2026"
5. WebSearch: "como [problema] [keyword1]"
6. WebSearch: "[keyword1] comprar/assinar"
Repetir para cada keyword.

Para CADA resultado: extrair nome, dominio, tipo de resultado (organico/ad).
Escrever IMEDIATAMENTE em: objetivo-1-concorrentes/busca-google.md
Formato por linha: | Nome | URL | Tipo (organico/ad) | Keyword que encontrou |
Se busca retorna >50% irrelevante → refinar com aspas ou qualificadores.
```

**Subagente 2 — Google Dorking:**
```
TAREFA: Encontrar landing pages com anuncios Meta no nicho [NICHO].

EXECUTAR:
1. WebSearch: intext:"This site is not a part of the Facebook" intext:[keyword1]
2. WebSearch: intext:"This site is not a part of the Facebook" intext:[keyword2]
3. WebSearch: intext:"This site is not a part of the Facebook" intext:[keyword3]
4. WebSearch: intext:"Este site nao faz parte do Facebook" intext:[keyword1]

Para CADA resultado: extrair dominio, titulo da pagina.
Escrever em: objetivo-1-concorrentes/dork-facebook.md
Formato: | Dominio | Titulo | Keyword |
```

**Subagente 3 — Marketplaces:**
```
TAREFA: Encontrar produtos/produtores em marketplaces digitais no nicho [NICHO].

EXECUTAR:
1. WebSearch: site:hotmart.com [keyword1]
2. WebSearch: site:kiwify.com.br [keyword1]
3. WebSearch: site:eduzz.com [keyword1]
4. WebSearch: site:monetizze.com.br [keyword1]
5. WebSearch: "mais vendidos [nicho] hotmart"
6. WebSearch: "mais vendidos [nicho] kiwify"
7. WebSearch: site:hotmart.com [keyword2]
8. WebSearch: site:kiwify.com.br [keyword2]
9. WebSearch: "[nicho] produto digital"
10. WebSearch: "[nicho] curso online"

Para CADA resultado: extrair nome do produto, produtor, plataforma, URL.
Escrever em: objetivo-1-concorrentes/marketplaces.md
Formato: | Produto | Produtor | Plataforma | URL |
```

**Subagente 4 — YouTube + Google Trends:**
```
TAREFA: Encontrar concorrentes via YouTube e Google Trends no nicho [NICHO].

EXECUTAR:
1. WebSearch: site:youtube.com "[keyword1]" ad
2. WebSearch: site:youtube.com "[keyword1]" review
3. WebSearch: "[keyword1] youtube canal"
4. WebSearch: site:youtube.com "[keyword2]" curso
5. WebSearch: "[nicho] google trends 2025 2026"
6. WebSearch: "[keyword1]" trending

Para CADA canal/pessoa: extrair nome, URL do canal, tipo de conteudo.
Escrever em: objetivo-1-concorrentes/youtube-trends.md
```

**Subagente 5 — Reclame Aqui + Forums:**
```
TAREFA: Encontrar concorrentes via Reclame Aqui e forums no nicho [NICHO].

EXECUTAR:
1. WebSearch: site:reclameaqui.com.br "[keyword1]"
2. WebSearch: site:reclameaqui.com.br "[keyword2]"
3. WebSearch: site:reclameaqui.com.br "[nicho] curso"
4. WebSearch: site:reddit.com "[problema em ingles]"
5. WebSearch: "[nicho] grupo facebook"
6. WebSearch: "[nicho] comunidade"
7. WebSearch: "[nicho] reclamacao"

Para CADA resultado: extrair nome/marca, URL, contexto.
Escrever em: objetivo-1-concorrentes/reclameaqui-forums.md
```

**Pos-lote:** Agente principal verifica se os 5 arquivos existem e tem conteudo. Re-dispara qualquer subagente que falhou.

### Etapa 2: Discovery — Concorrentes INDIRETOS

Disparar 2 subagentes:

**Subagente "Arvore de Solucoes":**
```
TAREFA: Encontrar concorrentes INDIRETOS — quem resolve o mesmo PROBLEMA de forma DIFERENTE.
Problema do publico: [PROBLEMA]
Nicho: [NICHO]

EXECUTAR:
1. WebSearch: "como [resolver o problema] site:.com.br"
2. WebSearch: "alternativas para [tipo de produto]"
3. WebSearch: "[problema] solucao diferente"
4. WebSearch: "[problema] app"
5. WebSearch: "[problema] profissional"
6. WebSearch: "[problema] metodo"
7. WebSearch: "[problema] tratamento"
8. WebSearch: "[problema] servico"

Para cada TIPO de solucao diferente encontrada:
- Classificar a categoria (app, servico, produto fisico, profissional, curso, etc.)
- Listar quem oferece

Escrever em: objetivo-1-concorrentes/indiretos-solucoes.md
Formato: | Categoria | Nome | URL | Como resolve o problema |
```

**Subagente "Competidores por Atencao":**
```
TAREFA: Encontrar quem compete pela ATENCAO do mesmo publico-alvo.
Publico: [PUBLICO]
Nicho: [NICHO]

EXECUTAR:
1. WebSearch: "[publico-alvo] influencer instagram"
2. WebSearch: "[publico-alvo] canal youtube"
3. WebSearch: "[publico-alvo] blog"
4. WebSearch: "[publico-alvo] podcast"
5. WebSearch: "[nicho] criador de conteudo"

Para CADA resultado: extrair nome, plataforma, URL, tipo de conteudo.
Escrever em: objetivo-1-concorrentes/indiretos-atencao.md
```

### Etapa 3: Validacao de Anunciantes Ativos

**CRITICO:** Meta de 70%+ anunciantes ativos confirmados.

Agente principal:
1. Le todos os arquivos da Etapa 1 e 2
2. Compila lista unica de concorrentes em `_concorrentes.md`
3. Aplica deduplicacao (normalizar URLs, agrupar por dominio raiz)
4. Aplica detector de afiliado (remover afiliados da lista de concorrentes)
5. Dispara subagentes de validacao em lotes de 5

**Para cada lote de 5 concorrentes, subagente de validacao:**
```
TAREFA: Validar se estes concorrentes sao anunciantes ativos.
Concorrentes: [LISTA DE 5 com nome + URL]

Para CADA concorrente, executar TODOS estes checks:
1. WebSearch: "[nome/marca]" facebook ads library
2. WebSearch: "[dominio]" ads
3. WebSearch: "[marca]" anuncio
4. WebSearch: "[marca]" "sponsored" OR "patrocinado"
5. WebSearch: "[dominio]" google ads
6. WebFetch: [URL principal] → analisar HTML:
   - Tem fbq( ou facebook pixel? → +1 ponto
   - Tem gtag( ou Google Ads tag? → +1 ponto
   - Tem ttq ou TikTok pixel? → +1 ponto

SCORE:
- 0-1 positivos = PROVAVELMENTE INATIVO
- 2-3 positivos = POSSIVELMENTE ATIVO
- 4+ positivos = CONFIRMADO ATIVO

SE score baixo (0-1), tentar FALLBACKS:
- WebSearch pelo nome do expert/dono (nao so marca)
- WebSearch pelo @ do Instagram
- WebSearch pelo dominio sem www
- WebSearch variacoes do nome (com/sem acento, abreviado)
- WebSearch pelo nome do produto principal
SO marcar "dados insuficientes" se TODOS falharem (7+ tentativas).

Escrever em: objetivo-1-concorrentes/validacao-lote-[N].md
Formato: | Nome | URL | Score | Checks positivos | Status |
```

### Etapa 4: Compilacao

Agente principal:
1. Le todos os arquivos de validacao
2. Merge na `_concorrentes.md` com scores
3. Gera `relatorio-final.md`:
   - Total encontrados: X diretos + Y indiretos
   - Anunciantes confirmados: Z% (meta: 70%+)
   - Top 10 por score (candidatos para OBJ 3)
   - Lista completa organizada por tipo
4. Atualiza `_estado.md`: "OBJETIVO 1 COMPLETO"

Se <70% anunciantes ativos:
- WebSearch "maiores [nicho] brasil 2026"
- WebSearch "top [tipo de produto] [nicho]"
- WebSearch "[nicho] quem sao os lideres"
- Adicionar novos nomes encontrados e re-validar

---

## OBJETIVO 2: ENCONTRAR OFERTAS ESCALADAS

**Meta:** Lista de ofertas validadas com score de escala (3+ testes = confirmada).

### Etapa 1: Discovery — 8 Metodos (subagentes em lotes)

**Lote 1 (3 subagentes):**

**Subagente M1 — Busca por Ads:**
```
TAREFA: Encontrar ofertas com anuncios ativos no nicho [NICHO].

EXECUTAR:
1. WebSearch: "[keyword1]" facebook ad 2025 2026
2. WebSearch: "[keyword2]" anuncio facebook
3. WebSearch: "[keyword1]" instagram ad
4. WebSearch: "[keyword1]" youtube ad
5. WebSearch: "[nicho]" ad running
6. WebSearch: "[keyword1]" google ads

Para CADA anunciante: nome, URL destino, tempo ativo estimado.
Escrever em: objetivo-2-ofertas/m1-ads.md
```

**Subagente M3 — Google Dork Checkouts:**
```
TAREFA: Encontrar produtos ativos via checkouts indexados no nicho [NICHO].

EXECUTAR:
1. WebSearch: site:pay.kiwify.com.br [keyword1]
2. WebSearch: site:go.hotmart.com [keyword1]
3. WebSearch: site:pay.hotmart.com [keyword1]
4. WebSearch: site:app.monetizze.com.br [keyword1]
5. WebSearch: site:sun.eduzz.com [keyword1]
6. Repetir para keyword2 e keyword3.
7. WebSearch: site:pay.kiwify.com.br [keyword2]
8. WebSearch: site:go.hotmart.com [keyword2]

Cada resultado = produto ativo naquele nicho.
Escrever em: objetivo-2-ofertas/m3-checkouts.md
Formato: | Produto | Plataforma | URL checkout | Keyword |
```

**Subagente M4 — Reclame Aqui (paradoxo do volume):**
```
TAREFA: Encontrar ofertas com alto volume de vendas via reclamacoes.
Logica: MAIS reclamacoes = MAIS vendas. Ninguem reclama de produto que ninguem compra.

EXECUTAR:
1. WebSearch: site:reclameaqui.com.br "[keyword1]"
2. WebSearch: site:reclameaqui.com.br "[keyword2]"
3. WebSearch: site:reclameaqui.com.br "[nicho] curso"
4. WebSearch: site:reclameaqui.com.br "[nicho] produto"
5. WebSearch: "[keyword1]" reclameaqui reclamacoes

Para CADA resultado: nome da empresa/produto, volume de reclamacoes, nota.
Escrever em: objetivo-2-ofertas/m4-reclameaqui.md
```

**Lote 2 (3 subagentes):**

**Subagente M5 — YouTube + Reviews:**
```
TAREFA: Encontrar ofertas escaladas via YouTube no nicho [NICHO].

EXECUTAR:
1. WebSearch: "[keyword1]" youtube ad views
2. WebSearch: "[keyword1]" review youtube
3. WebSearch: "[keyword2]" review youtube
4. WebSearch: "[nicho]" "funciona mesmo" youtube
5. WebSearch: "[nicho]" "vale a pena" youtube
6. WebSearch: "[keyword1]" unboxing OR review

Ads com muitos views/comentarios = escala.
Escrever em: objetivo-2-ofertas/m5-youtube.md
```

**Subagente M13 — Google Dork Disclaimer Facebook:**
```
TAREFA: Encontrar TODAS as landing pages com anuncios Meta no nicho.

EXECUTAR:
1. WebSearch: intext:"This site is not a part of the Facebook" intext:[keyword1]
2. WebSearch: intext:"This site is not a part of the Facebook" intext:[keyword2]
3. WebSearch: intext:"This site is not a part of the Facebook" intext:[keyword3]
4. WebSearch: intext:"Este site nao faz parte do Facebook" intext:[keyword1]

Cada resultado = oferta ativa com ads Meta.
Escrever em: objetivo-2-ofertas/m13-disclaimer.md
```

**Subagente M6 — Google Trends:**
```
TAREFA: Analisar tendencias de busca para marcas/produtos do nicho.

EXECUTAR:
1. WebSearch: "[marca1]" google trends
2. WebSearch: "[marca2]" vs "[marca3]" tendencia
3. WebSearch: "[nicho]" tendencia 2025 2026
4. WebSearch: "[keyword1]" volume busca crescendo
5. WebSearch: google trends "[keyword1]" "[keyword2]"

Classificar: subindo = escalando agora, estavel 6+ meses = evergreen, caindo = saturando.
Escrever em: objetivo-2-ofertas/m6-trends.md
```

**Lote 3 (2 subagentes — analise de dominios encontrados):**

Para os TOP 20 dominios encontrados nos lotes anteriores:

**Subagente M2 — Trafego Estimado:**
```
TAREFA: Estimar trafego dos top dominios encontrados.
Dominios: [LISTA DOS TOP 20]

NUNCA tentar WebFetch em SimilarWeb (bloqueado).
Para CADA dominio:
1. WebSearch: "[dominio]" traffic monthly visitors
2. WebSearch: "[dominio]" similarweb
3. WebSearch: "[dominio]" alexa rank
4. Se encontrar dados → registrar estimativa

Escrever em: objetivo-2-ofertas/m2-trafego.md
Formato: | Dominio | Trafego estimado | Fonte do dado |
```

**Subagente M11 — Archive.org:**
```
TAREFA: Verificar historico e frequencia de snapshots no Archive.org.
Dominios: [LISTA DOS TOP 20]

Para CADA dominio:
1. WebFetch: web.archive.org/web/*/[dominio]
2. Se bloqueado → WebSearch: "[dominio]" archive.org snapshots
3. Anotar: frequencia de capturas (diario/semanal/mensal/raro)
   - Diario = muito trafego = muito escalado
   - Semanal = trafego medio
   - Mensal/raro = pouco trafego

Escrever em: objetivo-2-ofertas/m11-archive.md
```

### Etapa 2: Validacao Cruzada

Subagente de validacao:
```
TAREFA: Validar ofertas encontradas com score de escala.

Para CADA oferta candidata, checar:
1. Longevidade: evidencia de anuncio > 30 dias? (+1)
2. Trafego: estimativa > 50K/mes? (+1)
3. Quantidade de anuncios ativos > 5? (+1)
4. Aparece em checkout de plataforma? (+1)
5. Tem reclamacoes no Reclame Aqui? (+1)
6. Google Trends com volume? (+1)
7. Encontrada por mais de 1 metodo? (+1)

SCORE:
- 0-2 = DUVIDOSA
- 3-4 = VALIDADA
- 5+ = CONFIRMADA ESCALADA

Escrever em: objetivo-2-ofertas/validacao.md
```

### Etapa 3: Analise de Estrutura (ofertas com score 3+)

Para cada oferta validada, subagente de analise:
```
TAREFA: Analisar estrutura da oferta [NOME] em [URL].

1. WebFetch na pagina de vendas
2. Extrair:
   - Headline principal (promessa)
   - Sub-headline
   - Mecanismo unico (o "por que" funciona)
   - Estrutura de preco (valor, parcelas, desconto)
   - Bonus listados
   - Tipo de garantia (7/30/90 dias)
   - Urgencia/escassez (timer, vagas)
   - CTA (texto do botao)
   - Plataforma de checkout
3. Se pagina JS-heavy (HTML vazio):
   - Extrair de <meta og:title>, <meta og:description>
   - Extrair pixel IDs de <script> tags
   - WebSearch: cache:[url]

Escrever em: objetivo-2-ofertas/estrutura-[nome-normalizado].md
```

### Etapa 4: Compilacao

Agente principal gera:
- `_ofertas.md`: lista ranqueada com scores
- `estruturas.md`: analise da estrutura de cada oferta validada
- `padroes.md`: o que as top ofertas tem em comum (headlines, precos, garantias, mecanismos)

---

## OBJETIVO 3: CONCORRENTES ESCALADOS

**Meta:** Ranking de escala + dossie profundo dos top 5-10.

### Etapa 1: Ranking por Escala

Para cada concorrente (lotes de 5 subagentes):

**Subagente de Ranking:**
```
TAREFA: Avaliar nivel de escala do concorrente [NOME] ([URL]).

1. WebSearch: "[marca]" ads ativos facebook
2. WebSearch: "[dominio]" traffic visitors
3. WebSearch: "[marca]" google trends volume
4. WebFetch: [URL] → contar pixels, tags, complexidade da stack
5. WebSearch: site:reclameaqui.com.br "[marca]"

SCORE (1-15, 5 pontos por criterio):
A. Volume de ads (0-5): nenhum=0, 1-3=1, 4-10=3, 10+=5
B. Trafego estimado (0-5): <10K=0, 10-50K=2, 50-200K=4, 200K+=5
C. Presenca/busca (0-5): nenhuma=0, alguma=2, significativa=4, dominante=5

Escrever em: objetivo-3-escalados/ranking-[nome].md
Formato: Nome | URL | Score A | Score B | Score C | TOTAL
```

Agente principal ordena e seleciona top 5-10 para deep dive.

### Etapa 2: Deep Dive (1 subagente pesado por concorrente)

**Para cada concorrente-alvo, subagente executa TODA a sequencia:**

```
TAREFA: Gerar dossie completo do concorrente [NOME] ([URL]).
Escrever TUDO em: objetivo-3-escalados/dossies/dossie-[nome].md
Escrever CADA achado IMEDIATAMENTE apos encontra-lo. Nunca acumular.

=== B1. REDE DE DOMINIOS ===
1. WebFetch: [URL principal] → extrair TODOS pixel IDs (fbq, gtag, gtm) do HTML
2. WebSearch: "[pixel ID]" builtwith → outros dominios com mesmo pixel
3. WebSearch: site:*.[dominio] → subdominios
4. WebSearch: "[dominio]" related domains
5. WebFetch: viewdns.info/reverseip/?host=[dominio]
   SE bloqueado → WebSearch: "viewdns [dominio] reverse ip"
   SE bloqueado → WebSearch: "[dominio] hosted sites"
   SE bloqueado → WebSearch: "securitytrails [dominio] subdomains"

Registrar: lista completa de dominios da operacao.

=== B2. TRAFEGO REAL ===
Para CADA dominio da rede:
1. WebSearch: "[dominio]" traffic monthly
2. WebSearch: "[dominio]" similarweb
Somar TUDO = trafego real da operacao.

=== B3. STACK TECNOLOGICO ===
WebFetch: [URL principal] → analisar HTML completo:
- Construtor (ClickFunnels, WordPress, Convertri, etc.)
- Email marketing (ActiveCampaign, MailChimp, etc.)
- Processador pagamento (Kiwify, Hotmart, Stripe, etc.)
- Pixels: Meta, Google, TikTok
- CDN, chat, CRM

=== B4. PAGINAS DO FUNIL ===
Executar Google Dorking completo:
1. WebSearch: site:[dominio]
2. WebSearch: site:[dominio] inurl:upsell
3. WebSearch: site:[dominio] inurl:obrigado
4. WebSearch: site:[dominio] inurl:checkout
5. WebSearch: site:[dominio] inurl:oto
6. WebSearch: site:[dominio] inurl:thankyou
7. WebSearch: site:[dominio] inurl:members
8. WebSearch: site:[dominio] inurl:especial
9. WebSearch: site:[dominio] inurl:webinar
10. WebSearch: site:[dominio] inurl:aula
11. WebSearch: site:[dominio] inurl:downsell
12. WebSearch: site:[dominio] inurl:upgrade
13. WebSearch: site:[dominio] inurl:oferta
14. WebFetch: [dominio]/robots.txt
15. WebFetch: [dominio]/sitemap.xml
16. WebFetch: [dominio]/wp-sitemap.xml

Registrar: lista de TODAS as URLs encontradas com classificacao.

=== B5. PRESENCA SOCIAL ===
1. WebSearch: "[marca]" instagram
2. WebSearch: "[marca]" instagram bio link
3. WebSearch: "[marca]" linktr.ee OR linkin.bio
4. Se encontrar link da bio → WebFetch no link
5. WebSearch: "[marca]" tiktok
6. WebSearch: "[marca]" youtube canal

=== B6. CRIATIVOS (swipefile) ===
1. WebSearch: "[marca]" facebook ad anuncio
2. WebSearch: "[marca]" anuncio patrocinado
3. Para cada anuncio encontrado: formato, hook, URL destino, tempo ativo
4. Salvar em: swipefile/criativos-[nome].md

=== B7. DADOS DO PROPRIETARIO ===
1. WebSearch: "[dominio]" whois registrante
2. WebSearch: "[dominio]" registro.br
3. Se encontrar CNPJ → WebSearch: "[CNPJ]" outros dominios
4. Se encontrar email → WebSearch: "[email]" dominios

COMPILAR dossie final com formato:
# Dossie: [NOME]
## Rede de Dominios
## Trafego Real Total
## Stack Tecnologico
## Paginas do Funil
## Presenca Social
## Criativos
## Dados do Proprietario
## INSIGHTS: pontos fortes, fraquezas, oportunidades
```

### Etapa 3: Compilacao

Agente principal gera:
- `ranking.md`: ranking final com scores
- `comparativo.md`: o que todos os top tem em comum vs. diferenciais
- `oportunidades.md`: gaps e oportunidades identificadas

---

## OBJETIVO 4: MAPEAR FUNIL COMPLETO DE UM CONCORRENTE

**Meta:** Mapa completo de todas as paginas, fluxo, classificacao de cada etapa.

### Etapa 1: Descoberta de Paginas

**Subagente pesado (1 unico, muitas queries):**
```
TAREFA: Descobrir TODAS as paginas do funil de [DOMINIO].
Escrever CADA achado IMEDIATAMENTE em: objetivo-4-funis/paginas-[nome].md

=== CAMADA 1: Busca Estrutural ===
1. WebFetch: [dominio]/robots.txt → listar Disallow (revela o que tentam esconder)
2. WebFetch: [dominio]/sitemap.xml
3. WebFetch: [dominio]/wp-sitemap.xml
4. WebFetch: [dominio]/sitemap_index.xml
5. WebFetch: [dominio]/post-sitemap.xml
6. WebFetch: [dominio]/page-sitemap.xml
7. WebFetch: pagina principal → extrair TODOS os links internos
8. WebFetch: pagina de vendas (se diferente) → extrair TODOS os links

=== CAMADA 2: Google Dorking Exaustivo ===
9. WebSearch: site:[dominio]
10. WebSearch: site:[dominio] inurl:upsell
11. WebSearch: site:[dominio] inurl:obrigado
12. WebSearch: site:[dominio] inurl:checkout
13. WebSearch: site:[dominio] inurl:oto
14. WebSearch: site:[dominio] inurl:order-bump
15. WebSearch: site:[dominio] inurl:thankyou
16. WebSearch: site:[dominio] inurl:members
17. WebSearch: site:[dominio] inurl:especial
18. WebSearch: site:[dominio] inurl:vip
19. WebSearch: site:[dominio] inurl:webinar
20. WebSearch: site:[dominio] inurl:aula
21. WebSearch: site:[dominio] inurl:downsell
22. WebSearch: site:[dominio] inurl:upgrade
23. WebSearch: site:[dominio] inurl:oferta
24. WebSearch: site:[dominio] inurl:login
25. WebSearch: site:[dominio] inurl:register
26. WebSearch: site:[dominio] inurl:promo

=== CAMADA 3: Engenharia Reversa de URLs ===
27. Se ClickFunnels: tentar /upsell, /oto, /order-confirmation, /members
28. Se Hotmart/Kiwify: extrair ID do produto → buscar outros IDs
29. Tentar variacoes: pagina-vendas-2, pagina-vendas-b, lp-v2, lp-a, lp-b

=== CAMADA 4: Subdominios ===
30. WebSearch: site:*.[dominio]
31. WebSearch: "[dominio]" subdominios

=== CAMADA 5: Rede de dominios ===
32. WebFetch: pagina principal → extrair pixel IDs
33. WebSearch: "[pixel ID]" builtwith
34. WebFetch: viewdns.info/reverseip/?host=[dominio]
    SE bloqueado → cadeias de fallback (ver SISTEMA DE FALLBACK)

Formato de saida por URL:
| URL | Como encontrou | Status (ativo/404/redirect) |
```

### Etapa 2: Fetch e Classificacao

Para cada URL descoberta (subagentes em lotes de 5):
```
TAREFA: Classificar paginas do funil [CONCORRENTE].
URLs para analisar: [LISTA]

Para CADA URL:
1. WebFetch na pagina
2. Classificar como:
   - LP (Landing Page / Captura)
   - VSL (Video Sales Letter)
   - PV (Pagina de Vendas - long copy)
   - PS (Pre-sell / Artigo / Quiz)
   - CK (Checkout)
   - OB (Order Bump — geralmente embutido no checkout)
   - UP (Upsell / OTO)
   - DS (Downsell)
   - TY (Thank You / Obrigado)
   - MB (Area de Membros)
   - WB (Webinar / Aula)
   - CS (Cross-sell)
   - BK (Backend / High Ticket)
   - OT (Outro)
3. Extrair: titulo/headline, preco (se visivel), links internos, formularios
4. Se pagina JS-heavy: extrair de meta tags, og: tags, script tags
5. Se pagina protegida: registrar como "PROTEGIDO - [tipo de plataforma]"

Escrever em: objetivo-4-funis/classificacao-[nome]-lote-[N].md
Formato: | URL | Tipo | Headline | Preco | Links para |
```

### Etapa 3: Montagem do Mapa

Agente principal compila tudo em `objetivo-4-funis/funil-[nome].md`:

```markdown
# Mapa do Funil: [CONCORRENTE]

## Fluxo Principal
ENTRADA (Anuncio/Link)
  → [LP] [headline] [URL] [CONFIRMADO]
     → [PV] [headline] [preco] [URL] [CONFIRMADO]
        → [CK] [plataforma] [URL] [CONFIRMADO]
           → [OB] [oferta] [preco] [INFERIDO]
           → [UP1] [oferta] [preco] [URL] [CONFIRMADO/INFERIDO]
              → SE aceita → [UP2]
              → SE recusa → [DS] [preco] [URL]
                 → [TY] [URL] [CONFIRMADO]
                    → [MB] [plataforma] [URL] [CONFIRMADO/PROTEGIDO]
                       → [BK] [URL] [INFERIDO]

## Versoes Alternativas de Paginas
- PV v1: [URL] headline: "..."
- PV v2: [URL] headline: "..."

## Paginas Descobertas Nao Mapeadas no Fluxo
| URL | Tipo | Nota |

## Stack Tecnologico
- Construtor: [X]
- Checkout: [X]
- Pixels: [lista]

## Confianca
- [CONFIRMADO] = pagina acessada e classificada
- [INFERIDO] = pagina provavelmente existe (URL descoberta mas inacessivel ou padrao da plataforma)
- [PROTEGIDO] = pagina existe mas requer senha/login
```

### Etapa 4: Swipefile Automatico

Para cada pagina do funil que foi acessada:
```
Salvar em swipefile/:
- copies-vendas.md: headlines, hooks, CTAs
- estruturas-oferta.md: precos, bonus, garantias
- criativos.md: formatos de anuncio encontrados
```

---

## SISTEMA DE FALLBACK

### Buscar concorrente/marca (7 tentativas antes de desistir):
```
1. WebSearch pelo nome da marca
2. WebSearch pelo nome do expert/dono
3. WebSearch pelo dominio
4. WebSearch pelo @ do Instagram
5. WebSearch pelo nome do produto principal
6. WebSearch pelo CNPJ (se WHOIS revelou)
7. WebSearch pelo email do registrante
→ SO marca "dados insuficientes" se TODOS falharem
```

### Buscar paginas do funil (8 tentativas):
```
1. Google Dorking (20+ variacoes)
2. robots.txt / sitemap.xml (6 variacoes de URL)
3. Analise de HTML (links internos)
4. Engenharia reversa de URLs por plataforma
5. Subdominios
6. ViewDnsInfo reverse IP
7. BuiltWith pixel network
8. Archive.org (paginas antigas que revelam estrutura)
→ SO marca "funil parcial" se TODOS falharem
```

### Buscar evidencia de escala (7 tentativas):
```
1. WebSearch por ads ativos
2. WebFetch + analise de pixels
3. Reclame Aqui (paradoxo do volume)
4. Google Trends volume
5. Marketplaces (ranking/temperatura)
6. Archive.org (frequencia de snapshots)
7. WHOIS (multiplos dominios = operacao grande)
→ SO marca "escala nao confirmada" se TODOS falharem
```

### Fallback de ferramentas especificas:

**ViewDnsInfo bloqueado:**
```
1. WebFetch viewdns.info → 2. WebSearch "viewdns [dominio]"
→ 3. WebSearch "[dominio] hosted sites"
→ 4. WebSearch "dnsdumpster [dominio]"
→ 5. WebSearch "securitytrails [dominio]"
→ 6. WebSearch "[dominio] related domains"
→ 7. Registrar "rede nao mapeavel" + compensar com pixel tracking
```

**SimilarWeb (NUNCA WebFetch direto):**
```
1. WebSearch "[dominio] traffic"
2. WebSearch "[dominio] similarweb"
3. WebSearch "[dominio] monthly visitors"
4. WebSearch "[dominio] alexa rank"
5. Estimar por sinais indiretos
```

**Instagram bloqueado:**
```
1. WebSearch "[usuario] instagram bio"
2. WebSearch "[usuario] instagram link"
3. WebSearch "[marca] linktr.ee" OR "linkin.bio"
4. Se encontrar link da bio → WebFetch nele
```

**Meta Ad Library (inacessivel):**
```
COMPENSAR COM:
1. Google Dork: intext:"This site is not a part of the Facebook" intext:[keyword]
2. WebFetch pagina → detectar Meta Pixel no HTML
3. WebSearch "[marca] facebook ad"
4. WebSearch "[marca] foreplay" ou "[marca] adspy"
LIMITACAO HONESTA: nao ve criativos reais, mas confirma que ANUNCIA e encontra landing pages.
```

---

## GERENCIAMENTO DE ESTADO

### Formato do _estado.md (APPEND-ONLY):
```
[YYYY-MM-DD HH:MM] EVENTO - Detalhes
```
Exemplos:
```
[2026-02-19 14:30] INICIO - Objetivo 1 - Setup completo
[2026-02-19 14:35] LOTE 1 DISPARADO - 5 subagentes
[2026-02-19 14:45] LOTE 1 COMPLETO - 32 concorrentes encontrados
[2026-02-19 14:46] LOTE 1 FALHA PARCIAL - subagente 4 sem output - RE-TENTANDO
[2026-02-19 14:50] RETENTATIVA LOTE 1/S4 COMPLETA - 8 concorrentes adicionais
```

### Prompt de Retomada
Se contexto encher ou sessao interromper, gerar `_prompt-retomada.md`:
```
Voce e o skill /funnel-hacking em modo de RETOMADA.

1. Leia o arquivo [path]/_estado.md para saber onde parou
2. Leia os arquivos ja criados em [path]/ para recuperar contexto
3. O objetivo ativo e: [OBJETIVO X]
4. A ultima etapa completa foi: [ETAPA Y]
5. O proximo passo e: [PASSO Z]
6. Nicho: [nicho]
7. Keywords: [keywords]
8. Concorrentes ja encontrados: [N] (ver _concorrentes.md)

Continue de onde parou. Nao refaca trabalho ja completo.
Consultar skill /funnel-hacking para instrucoes completas.
```

### Continuidade entre Objetivos
- Objetivo 1 gera `_concorrentes.md` → Objetivo 3 le como input
- Objetivo 2 gera `_ofertas.md` → pode cruzar com Objetivo 3
- Skill detecta automaticamente: "Ja existe output de objetivo anterior? Usar como base."

---

## FORMATO DE OUTPUT POR OBJETIVO

### Objetivo 1 — `objetivo-1-concorrentes/relatorio-final.md`:
```
# Relatorio de Concorrentes — [NICHO]
Data: [data]

## Resumo
- Total encontrados: X
- Diretos: Y | Indiretos: Z
- Anunciantes ativos confirmados: W (P%)

## Top 10 (candidatos para Objetivo 3)
| # | Nome | URL | Tipo | Score Ads | Status |

## Lista Completa — Diretos
| Nome | URL | Onde encontrou | Score Ads | Status |

## Lista Completa — Indiretos
| Nome | URL | Categoria | Onde encontrou |

## Metodologia
Fontes utilizadas: Google, Dorking, Marketplaces, YouTube, Reclame Aqui, Forums
Queries executadas: [N]
Fallbacks ativados: [N]
```

### Objetivo 2 — `objetivo-2-ofertas/relatorio-final.md`:
```
# Ofertas Escaladas — [NICHO]

## Top Ofertas (score 5+)
| # | Oferta | Score | Metodos que confirmaram | URL |

## Ofertas Validadas (score 3-4)
| # | Oferta | Score | URL |

## Estrutura das Top Ofertas
[Para cada top oferta: headline, mecanismo, preco, bonus, garantia, CTA]

## Padroes Identificados
- Headlines: [padrao]
- Precos: [faixa]
- Garantias: [padrao]
- Mecanismos: [tipos]
```

### Objetivo 3 — `objetivo-3-escalados/relatorio-final.md`:
```
# Concorrentes Escalados — [NICHO]

## Ranking de Escala
| # | Nome | Score Total | Ads | Trafego | Presenca |

## Comparativo dos Top [N]
| Aspecto | Concorrente 1 | Concorrente 2 | ... |

## Oportunidades
[Gaps e oportunidades identificadas]

## Dossies Individuais
[Link para cada dossie em dossies/]
```

### Objetivo 4 — `objetivo-4-funis/funil-[nome].md`:
```
# Funil Completo: [CONCORRENTE]

## Mapa do Fluxo
[Diagrama do fluxo completo]

## Paginas Descobertas
| URL | Tipo | Status | Headline | Preco |

## Stack Tecnologico
## Nível de Confiança por Página
```

---

## CHECKLIST DE VERIFICACAO POS-EXECUCAO

Antes de marcar qualquer objetivo como completo:

**Objetivo 1:**
- [ ] 20+ concorrentes na lista final?
- [ ] Mix de diretos E indiretos?
- [ ] 70%+ com status de anunciante confirmado?
- [ ] Deduplicacao aplicada?
- [ ] Afiliados filtrados?

**Objetivo 2:**
- [ ] Cada oferta tem score de validacao (minimo 3 testes)?
- [ ] Estrutura extraida para ofertas com score 3+?
- [ ] Padroes identificados entre top ofertas?

**Objetivo 3:**
- [ ] Ranking gerado com score numerico?
- [ ] Dossie completo para top 5-10?
- [ ] Cada dossie tem: rede de dominios, trafego, stack, paginas, social, criativos?
- [ ] Comparativo gerado?

**Objetivo 4:**
- [ ] Minimo 20 queries de Google Dorking executadas?
- [ ] robots.txt e sitemap tentados?
- [ ] Cada pagina classificada por tipo?
- [ ] Mapa do fluxo montado?
- [ ] Marcacao [CONFIRMADO] vs [INFERIDO] aplicada?

---

---

## OBJETIVO 5: CAPTURAR VSL DO CONCORRENTE (Download de Video Bloqueado)

**Input:** URL da pagina com a VSL (ou URL m3u8 direta)
**Output:** Arquivo MP4 salvo em `./vsls-capturados/`
**Players suportados:** Vturb, ConvertAI, Bunny.net, Wistia, Vimeo, HLS/M3U8 customizado

### Como funciona tecnicamente

Vturb e ConvertAI servem videos via **HLS (HTTP Live Streaming)** — o video e dividido em segmentos `.ts` apontados por um arquivo `.m3u8`. O player JavaScript monta esses segmentos no browser. O download captura esses segmentos e remonta em MP4.

### Metodo 1: Script automatico (mais rapido)

```bash
# Uso basico — tenta automaticamente
./scripts/download-vsl.sh https://concorrente.com.br/vsl

# Com nome customizado
./scripts/download-vsl.sh https://concorrente.com.br/vsl nome-do-arquivo

# Se ja tiver a URL m3u8 (capturada manualmente)
./scripts/download-vsl.sh "https://cdn.vturb.com.br/.../index.m3u8" vsl-concorrente
```

O script tenta 5 metodos em cascata, parando ao primeiro que funcionar:
1. `yt-dlp` automatico (detecta player Vturb, Bunny, Wistia, Vimeo, HLS)
2. `yt-dlp` com User-Agent de browser real (bypass de deteccao de bot)
3. `yt-dlp` com cookies do Chrome (para conteudo autenticado/paywall)
4. `ffmpeg` direta em URL m3u8 (para URLs m3u8 capturadas manualmente)
5. Instrucoes detalhadas para extracao manual via DevTools

### Metodo 2: Via agente (quando script nao resolve)

Se o script falhar nos 4 primeiros metodos, o agente executa via Bash:

```bash
# Extrair URL do stream sem baixar (util para diagnostico)
yt-dlp -g "URL_DA_PAGINA"

# Download direto com yt-dlp e ffmpeg em conjunto
yt-dlp --downloader ffmpeg -f "bestvideo+bestaudio" "URL_DA_PAGINA" -o "vsl.mp4"

# ffmpeg com URL m3u8 capturada manualmente
ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto \
       -i "URL_M3U8" -c copy output.mp4
```

### Metodo 3: Captura manual via DevTools (fallback humano)

Quando todos os metodos automaticos falham (ex: player com DRM pesado):

1. Abrir Chrome com DevTools (F12) → aba **Network**
2. Filtrar por `m3u8`
3. Abrir a pagina e dar PLAY no video
4. Copiar a URL da requisicao m3u8 que aparecer
5. Passar essa URL para o script: `./scripts/download-vsl.sh "URL_M3U8" nome`

**Extensoes de browser que capturam automaticamente:**
- Chrome: [HLS Downloader](https://chromewebstore.google.com/detail/hls-downloader/hkbifmjmkohpemgdkknlbgmnpocooogp)
- Firefox: [Live Stream Downloader](https://addons.mozilla.org/en-US/firefox/addon/live-stream-downloader/)
- Chrome: [Stream Recorder](https://www.hlsloader.com/)

### Dependencias necessarias

```bash
# Instalar (macOS)
brew install yt-dlp ffmpeg

# Verificar versoes
yt-dlp --version   # deve ser 2025.x ou mais recente
ffmpeg -version
```

### Limitacoes conhecidas

| Cenario | Status |
|---------|--------|
| Vturb sem protecao extra | Funciona (Metodo 1 ou 2) |
| ConvertAI padrao | Funciona (Metodo 1 ou 2) |
| Bunny.net CDN | Funciona (Metodo 1) |
| Wistia, Vimeo | Funciona (Metodo 1) |
| YouTube | Funciona (Metodo 1) |
| Vturb com token de acesso | Funciona (Metodo 3 — cookies) |
| Conteudo com DRM (Widevine) | Nao automatizavel — requer captura de tela |

### Integracao com Objetivo 4

Durante o mapeamento de funil (OBJ 4), ao encontrar pagina com VSL:
1. Registrar URL da pagina no mapa do funil
2. Executar OBJ 5 automaticamente para capturar a VSL
3. Salvar em `vsls-capturados/vsl-[concorrente]-[tipo].mp4`
4. Incluir no swipefile: duracao estimada, tipo de hook, angulo principal

---

## RECURSOS INCLUIDOS

- `references/metodologia-completa.md` — Documento-mestre com toda a teoria, conceitos e tecnicas detalhadas (Russell Brunson, 3 tipos de hacking, 16 tecnicas avancadas, ferramentas pagas, termos estrategicos)
- `references/fallbacks-e-falhas.md` — Auditoria completa de 31 pontos de falha com solucoes preventivas
- `scripts/google-dork-funnel.sh` — Script bash que gera TODAS as queries de Google Dorking para um dominio dado
- `scripts/download-vsl.sh` — Script bash para captura de VSL bloqueadas (Vturb, ConvertAI, HLS/M3U8) — 5 metodos em cascata com ffmpeg e yt-dlp
