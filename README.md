# Funnel Hacking Agent-Skill

Sistema autonomo de inteligencia de mercado (funnel hacking etico / benchmarking) que pesquisa, valida e gera dossies completos sem intervencao humana.

## O que e isso

Uma **Skill com orquestracao dinamica de subagentes** — o padrao mais poderoso para tarefas de pesquisa:

```
┌─────────────────────────────────────────────────┐
│           /funnel-hacking  (SKILL)               │
│                                                  │
│  Carregado no agente principal quando invocado   │
│  Diz ao Claude: o que fazer, em que ordem,       │
│  quais queries rodar, quais fallbacks usar       │
└──────────────────────┬──────────────────────────┘
                       │ orquestra
          ┌────────────┼────────────┐
          │            │            │
    ┌─────▼──┐   ┌─────▼──┐  ┌─────▼──┐
    │ SUB 1  │   │ SUB 2  │  │ SUB 3  │   ← Subagentes efemeros
    │Google  │   │Dork FB │  │Mercado │     (nascem, pesquisam,
    │Busca   │   │        │  │Places  │      escrevem em arquivo,
    └────────┘   └────────┘  └────────┘      morrem)
          │            │            │
          └────────────┼────────────┘
                       │ resultados salvos em
          ┌────────────▼────────────┐
          │    ARQUIVOS NO DISCO    │
          │  _estado.md             │  ← Estado persistente
          │  _concorrentes.md       │     (sobrevive entre sessoes)
          │  dossies/               │
          └─────────────────────────┘
```

- A **Skill** e o cerebro (sabe o que fazer)
- Os **Subagentes** sao os bracos (fazem o trabalho pesado, descartam contexto depois)
- Os **Arquivos** sao a memoria (sobrevivem entre sessoes, podem retomar de onde parou)

## Quando Usar

Use quando precisar:

1. Descobrir concorrentes de um nicho (20-40, diretos + indiretos)
2. Encontrar ofertas escaladas para modelar
3. Rankear concorrentes por escala e gerar dossies profundos
4. Mapear funil completo de um concorrente especifico
5. Construir swipefile automatico (copies, criativos, estruturas de oferta)

**Palavras-chave para ativar:** funnel hacking, concorrentes, ofertas escaladas, inteligencia de mercado, espionagem etica, benchmarking, funil, dossie, swipefile, escala

## Os 4 Objetivos

| # | Objetivo | Input | Output |
|---|----------|-------|--------|
| 1 | Descobrir Concorrentes | Nicho + keywords | Lista de 20-40 concorrentes, 70%+ anunciantes ativos |
| 2 | Encontrar Ofertas Escaladas | Nicho + keywords | Ofertas validadas com score de escala + estrutura |
| 3 | Concorrentes Escalados | Lista de concorrentes | Ranking de escala + dossie profundo dos top 5-10 |
| 4 | Mapear Funil Completo | URL de um concorrente | Mapa de todas as paginas, fluxo completo |

## Como Usar

### Uso standalone (qualquer projeto)

A skill esta instalada globalmente em `~/.claude/skills/` — disponivel em **qualquer projeto, em qualquer momento**, sem instalacao adicional.

Basta invocar:
```
/funnel-hacking
```

O sistema vai perguntar: objetivo (1, 2, 3, 4 ou todos), nicho, keywords — e executa tudo sozinho.

### Uso dentro de um squad de agentes

A skill pode ser integrada como **step de um processo sequencial** em squads de agentes.

**Forma A — Orquestrador chama a skill como step:**
```
Step 3: Executar /funnel-hacking com objetivo 1, nicho [X], keywords [Y]
        Aguardar completion dos arquivos em funnel-hacking/
        Ler funnel-hacking/objetivo-1-concorrentes/relatorio-final.md
        Passar lista de concorrentes para o Step 4
```

**Forma B — Orquestrador dispara como subagente via Task:**
```
Task: "Execute a metodologia do /funnel-hacking, Objetivo 1,
       nicho [X], salve em [pasta]. Retorne resumo dos top 10."
```

**Forma C — Squad le output ja gerado:**
```
funnel-hacking/_concorrentes.md      → input para agente de posicionamento
funnel-hacking/dossies/dossie-X.md   → input para agente de estrategia
funnel-hacking/swipefile/copies.md   → input para agente de copy
```

**Exemplo de squad com funnel-hacking como step:**
```
SQUAD: Lancamento de Produto
  │
  ├─ Step 1: RESEARCH (usa /funnel-hacking OBJ 1+2)
  │          Output: lista de concorrentes + ofertas escaladas
  │
  ├─ Step 2: INTELIGENCIA (usa /funnel-hacking OBJ 3)
  │          Le output do Step 1 + gera dossies dos top 5
  │
  ├─ Step 3: POSICIONAMENTO
  │          Le dossies → define diferencial → define mecanismo unico
  │
  ├─ Step 4: OFERTA
  │          Le padroes de ofertas escaladas → constroi escada de valor
  │
  └─ Step 5: COPY
             Le headlines dos concorrentes → cria versoes proprias
```

O output em arquivo torna a integracao facil: cada step le arquivos do step anterior, sem precisar passar dados pela memoria.

## Instalacao

Para instalar em uma nova maquina:

```bash
# Clonar o repositorio na pasta de skills do Claude Code
git clone https://github.com/Hackerdomarketing/Funnel-Hacking-Agent-Skill.git \
  ~/.claude/skills/funnel-hacking

# Tornar o script executavel
chmod +x ~/.claude/skills/funnel-hacking/scripts/google-dork-funnel.sh
```

## Estrutura da Skill

```
funnel-hacking/
├── SKILL.md                              # Instrucoes operacionais completas (1020 linhas)
├── README.md                             # Este arquivo
├── references/
│   ├── metodologia-completa.md           # Documento-mestre (2697 linhas, 12.704 palavras)
│   └── fallbacks-e-falhas.md             # 31 pontos de falha com solucoes preventivas
├── scripts/
│   └── google-dork-funnel.sh             # Gerador de queries Google Dorking
└── assets/                               # Templates e recursos futuros
```

## Output Gerado (no projeto ativo)

```
funnel-hacking/
  _estado.md                  ← Progresso (append-only com timestamps)
  _prompt-retomada.md         ← Prompt para continuar em nova sessao
  |
  |-- objetivo-1-concorrentes/
  |     _concorrentes.md      ← Lista master
  |     relatorio-final.md    ← Relatorio consolidado
  |
  |-- objetivo-2-ofertas/
  |     _ofertas.md           ← Ofertas com scores de escala
  |     estruturas.md         ← Analise de cada oferta
  |     padroes.md            ← Padroes entre top ofertas
  |
  |-- objetivo-3-escalados/
  |     ranking.md            ← Ranking com scores
  |     comparativo.md        ← Comparacao entre tops
  |     oportunidades.md      ← Gaps e oportunidades
  |     dossies/              ← 1 arquivo por concorrente
  |
  |-- objetivo-4-funis/
  |     funil-[nome].md       ← Mapa completo do funil
  |
  |-- swipefile/
        criativos.md          ← Anuncios coletados
        copies-vendas.md      ← Headlines, hooks, CTAs
        estruturas-oferta.md  ← Precos, bonus, garantias
```

## Script Google Dorking

Gera todas as queries de busca avancada para um dominio:

```bash
# Uso basico
./scripts/google-dork-funnel.sh exemplo.com.br

# Com keyword do nicho
./scripts/google-dork-funnel.sh exemplo.com.br "emagrecimento"
```

Gera queries para: paginas indexadas, paginas de funil (21 inurl:), subdominios, URLs diretas (robots.txt, sitemap), ferramentas de espionagem, evidencia de ads, trafego, WHOIS, e padroes de URL por plataforma.

## Personalidade do Sistema

**INCANSAVEL.** Nao desiste ate esgotar todos os metodos. Se um falha, tenta o proximo na cadeia de fallback. So marca "dados insuficientes" apos 7+ tentativas falharem. Obsessivo com completude.

## Continuidade Entre Sessoes

Se o contexto encher ou a sessao for interrompida:
1. Todo progresso esta salvo em arquivos
2. `_estado.md` tem log completo do que foi feito
3. `_prompt-retomada.md` tem prompt pronto para continuar
4. Basta colar o prompt de retomada numa nova sessao

## Metodologia

Baseado em:
- Funnel Hacking (Russell Brunson — ClickFunnels, DotCom Secrets, Expert Secrets, Traffic Secrets)
- Benchmarking competitivo do mercado digital brasileiro
- 16 tecnicas avancadas de espionagem etica (3 niveis)
- 14 metodos de descoberta de ofertas escaladas
- 31 pontos de falha auditados com solucoes preventivas
