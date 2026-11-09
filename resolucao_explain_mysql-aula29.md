# Lendo o Plano de Execução com EXPLAIN (MySQL 8.0.18+)

> **Aviso de honestidade:** não havia servidor MySQL disponível no ambiente em que esta resolução foi preparada. Nada abaixo foi executado. As colunas marcadas **(previsão)** são previsões técnicas; **tempos e `rows` exatos precisam ser coletados** rodando o arquivo `lab_otimizacao_explain.sql`. As contagens de dados (ex.: 10 locações por cliente) vêm de cálculo sobre o script de carga, não de execução.

## Fatos derivados do script de carga

- `id_cliente = 1 + (n*7919) % 50000`: como 7919 é primo e não divide 50.000, cada cliente aparece exatamente **10 vezes** nas 500.000 locações. Q1 devolve **10 linhas**.
- Status: `cancelada` = 10.000 (2%), `aberta` = 120.000 (24%), `concluida` = 370.000 (**74%**, não 73%; o enunciado diz "cerca de").
- Datas: ciclo de 1.095 dias a partir de 2023-01-01, ou seja, ~457 locações por dia; junho de 2025 (30 dias) ≈ 13.700 linhas (~2,7%).
- `nome LIKE 'Cliente 123%'` casa 111 clientes (123, 1230–1239, 12300–12399). `LIKE '%123'` casa 50.
- `cpf = '00000004242'` é único (cliente 4242).

---

# ENTREGÁVEL A — RESOLUÇÃO COMPLETA

## Parte 0 — Preparação

Rode o bloco "PARTE 0" do script. Resultados esperados: banco `lab_otimizacao` listado; tabelas `cliente` e `locacao`; `COUNT(*)` = 50000 e 500000; `SHOW INDEX` mostrando **apenas `PRIMARY`** nas duas tabelas (não aparece nenhum índice sobre `id_cliente`, `cpf`, etc.). Se `COUNT` divergir, a CTE recursiva foi cortada: confira `cte_max_recursion_depth`.

## Parte 1 — Diagnóstico sem índices

| Consulta | Tabela | type | key | rows | Extra / Observações |
|---|---|---|---|---|---|
| Q1 | locacao | ALL (previsão) | NULL | ~500.000 (estimativa; validar) | `Using where`; filtered ≈ 10% |
| Q2 | cliente | ALL (previsão) | NULL | ~50.000 (validar) | `Using where`; filtra `cpf` |
| Q2 | locacao | ALL (previsão) | NULL | ~500.000 (validar) | Provável `Using where; Using join buffer (hash join)` (hash join existe desde 8.0.18) |

A ordem de junção do Q2 depende do otimizador; é possível ele varrer `locacao` e usar PRIMARY de `cliente` (eq_ref). **Valide o plano real.**

**Tempo real da Q1 (sem índice): ______ ms** (coletar: `EXPLAIN ANALYZE` mostra `actual time=<primeira linha>..<última linha>`; use o segundo valor do nó mais externo).

**Interpretação**
- `type`: forma de acesso. `ALL` = varredura completa (a pior).
- `key`: índice efetivamente escolhido (NULL = nenhum).
- `rows`: **estimativa** de linhas a examinar.
- `Extra`: detalhes (`Using where` = filtro aplicado depois de ler a linha; `Using index` = coberto pelo índice; `Using join buffer (hash join)` = junção por hash).

**Por que lê a tabela inteira?** Sem índice secundário em `id_cliente`, as linhas estão organizadas pela PK (`id`), e nada permite localizar "id_cliente = 4242" sem testar linha por linha. O custo é proporcional ao tamanho da tabela, O(N), mesmo retornando só 10 linhas.

**EXPLAIN × EXPLAIN ANALYZE:** `EXPLAIN` só estima (usa estatísticas, não executa). `EXPLAIN ANALYZE` **executa** a consulta e mostra, ao lado da estimativa (`rows=` / `cost=`), os valores reais (`actual time=`, `rows=`, `loops=`). Diferenças grandes indicam estatísticas desatualizadas ou distribuição irregular. Em Q1 esperam-se: no nó `Table scan`, ~500.000 linhas lidas; no `Filter`, `rows=10`.

## Parte 2 — Criando índices e comparando

| Consulta | Tabela | type | key | rows |
|---|---|---|---|---|
| Q1 | locacao | ref (previsão) | idx_loc_cliente | ~10 (validar) |
| Q2 | cliente | ref (previsão; `const` não ocorre pois `cpf` não é único no esquema) | idx_cli_cpf | 1 (validar) |
| Q2 | locacao | ref (previsão) | idx_loc_cliente | ~10 (validar) |

**Tempo da Q1 antes: ______ ms. Tempo da Q1 depois: ______ ms.** (coletar com `EXPLAIN ANALYZE`; o ganho esperado é de ordens de grandeza, mas o número exato depende da máquina e do cache.)

**Análise**
1. `type` passa de `ALL` para `ref`: de varredura completa para busca por igualdade em índice não único.
2. Linhas examinadas caem de ~500.000 para ~10: o índice B-tree localiza a faixa de entradas com `id_cliente = 4242` em O(log N) e acessa apenas as 10 linhas correspondentes pela PK.
3. Em Q2, `idx_cli_cpf` encontra o único cliente com aquele CPF **antes** do JOIN; com o `id` obtido, `idx_loc_cliente` busca suas locações. Cada etapa é uma busca no índice, não uma varredura.

### 2.1 Seletividade

| Filtro | Parcela aproximada | type | key |
|---|---|---|---|
| status = 'cancelada' | ~2% (10.000) | ref (previsão) | idx_loc_status |
| status = 'concluida' | ~74% (370.000) | ALL (previsão) | NULL (validar) |

**Por que o índice serve para "cancelada" mas não para "concluida"?**
- **Seletividade:** fração de linhas que o filtro retorna. "cancelada" é muito seletiva (2%); "concluida" quase não filtra nada (74%).
- **Cardinalidade:** `status` tem apenas 3 valores distintos (`SHOW INDEX` → coluna `Cardinality` ≈ 3), por isso é um índice de baixa seletividade em geral.
- **Custo do índice:** ler o índice é barato, mas cada entrada leva a um acesso à linha na PK (lookup), em geral acesso aleatório.
- **Custo da tabela:** para 74% das linhas, fazer 370 mil lookups aleatórios custa mais que uma varredura sequencial da tabela inteira.
- **Estatísticas:** o otimizador compara custos estimados com base em estatísticas (`ANALYZE TABLE`, mergulhos no índice). Estatísticas velhas ou outra versão podem mudar a escolha; o limite exato não é fixo.
- **Índice existir ≠ ser usado:** a decisão é por custo, em cada consulta. O `aberta` (24%) é um caso de fronteira: vale testar.

## Parte 3 — Índices que o MySQL ignora

| Caso | type antes | type depois | Por que o índice não era usado? |
|---|---|---|---|
| 3A | ALL | range (idx_loc_data) | `DATE_FORMAT()` aplicada à coluna: é preciso calcular a função para cada linha |
| 3B | ALL | range (idx_cli_nome) | `%` no início: não há prefixo para posicionar a busca na B-tree |
| 3C | ALL | ref (idx_cli_cpf) | Comparação `VARCHAR = número`: coluna convertida para número em cada linha |

(Tipos "antes/depois" são previsões; validar.)

**3A.** Reescrita (junho/2025):
```sql
WHERE data_retirada >= '2025-06-01' AND data_retirada < '2025-07-01'
```
Um índice B-tree guarda os valores **ordenados**; a função esconde o valor da coluna, e o otimizador não consegue deduzir qual faixa do índice contém os resultados. Uma condição é **sargable** (*Search ARGument ABLE*) quando a coluna aparece "nua" no predicado, permitindo uma busca por faixa. Com intervalo, o MySQL desce a B-tree até o primeiro valor ≥ limite inferior e lê sequencialmente até o limite superior (exclusivo, o que evita problemas com horas e com "último dia do mês").

**3B.** Em `LIKE 'texto%'` o prefixo fixo define um intervalo no índice ordenado (de `'Cliente 123'` até logo antes de `'Cliente 124'`), por isso vira `range`. Em `LIKE '%texto'` o valor pode começar com qualquer coisa, e sem ordenação útil o índice B-tree não localiza; o MySQL lê tudo (pode até varrer o índice inteiro, o que `Extra` mostraria como `Using index`, se ele cobrir a consulta; com `SELECT *` não cobre). Para busca por sufixo/trecho, usa-se FULLTEXT, coluna invertida (reverse) ou outra estratégia.

**3C.** Reescrita: `cpf = '00000004242'`. `cpf` é VARCHAR porque é identificador, não número: tem zeros à esquerda, e não se faz aritmética com ele. Ao comparar string com inteiro, o MySQL converte os dois lados para número (ponto flutuante); a coluna é convertida linha a linha, então o índice em `cpf` não serve. Além de lento, é impreciso: `'00000004242'`, `'4242'` e `'4242abc'` se igualam a 4242. **Atenção:** o oposto não é regra geral. Coluna **numérica** comparada com literal string normalmente continua usando o índice, pois a constante é que é convertida. O problema aqui é a conversão ocorrer **no lado da coluna**. Para confirmar o uso do índice: `EXPLAIN` (coluna `key`) e `SHOW WARNINGS` logo depois (mostra a consulta reescrita pelo otimizador); `EXPLAIN ANALYZE` mostra `Index lookup on cliente using idx_cli_cpf` ou `Table scan`.

## Parte 4 — Índice composto

**Consulta A** (`id_cliente = 4242 AND data_retirada >= '2025-01-01'`)
1. Previsão: `idx_loc_cli_data`, `type = range` (possíveis também `idx_loc_cliente`, listado em `possible_keys`). Validar.
2. É eficiente porque o índice está ordenado primeiro por `id_cliente` e, dentro de cada cliente, por `data_retirada`. A igualdade posiciona na seção do cliente 4242, e a faixa de data é percorrida de forma contígua; não há linhas descartadas depois.
3. **Prefixo à esquerda:** um índice (a, b) só é usado de forma eficiente por consultas que filtram `a`, ou `a` e `b`. Filtrar só por `b` não permite localizar nada, pois os `b` estão espalhados em cada seção de `a`.
4. **Consulta B** filtra só `data_retirada`, a segunda coluna. As datas aparecem repetidas em cada um dos 50.000 clientes, de modo que não formam uma faixa contígua. (Existe *skip scan* desde o MySQL 8.0.13, mas só compensa quando a primeira coluna tem poucos valores distintos; com 50.000 não é de se esperar.) Previsão: usa `idx_loc_data` (`range`).
5. Composto (id_cliente, data) serve para "cliente + data" e também cobre consultas só por cliente (substituiria `idx_loc_cliente`, que fica redundante). Simples (data) serve para filtros apenas por data, em ordem global de data.

**Organização lógica:** pense numa lista telefônica ordenada por sobrenome e, dentro dele, por nome: (1, 2023-01-05), (1, 2023-03-10), …, (2, 2023-01-02), … Achar "todos os sobrenomes Silva" é fácil; achar "todos os João" exige olhar todas as seções.

### 4.1 Índice invisível

Previsão para B com `idx_loc_data` invisível: `type = ALL` (ou, menos provável, uso do composto via skip scan). Validar.
- **Consegue usar `idx_loc_cli_data`?** Não eficientemente (só por skip scan/varredura de índice, improvável).
- **O composto ajuda sem filtrar a 1ª coluna?** Em geral não.
- **Por que o simples é mais apropriado?** Tem `data_retirada` como primeira coluna: a faixa é contígua.
- **Finalidade:** testar o efeito de *remover* um índice sem apagá-lo; se algo ficar lento, basta torná-lo visível de novo (instantâneo), sem recriar o índice.
- **Manutenção e armazenamento:** continua existindo, ocupa espaço e é **atualizado em todo INSERT/UPDATE/DELETE**; só o otimizador deixa de considerá-lo. Invisibilidade ≠ exclusão. (Exceção: a PRIMARY KEY não pode ser invisível.)

## Parte 5 — Fechamento

1. **Maior ganho: Q1 (e a parte de `locacao` em Q2).** O plano passa de `type = ALL` com ~500 mil linhas para `type = ref` (`key = idx_loc_cliente`) com ~10 linhas. O tempo medido (a coletar) deve cair em ordens de grandeza.
2. **Índice existente não usado:** `idx_loc_status` para `status = 'concluida'` (~74%): o custo de milhares de acessos aleatórios à tabela supera o de uma varredura completa. Também `idx_cli_cpf` em `cpf = 4242` e `idx_cli_nome` em `LIKE '%123'`.
3. **Custo de escrita:** cada INSERT/DELETE altera todos os índices secundários (B-trees), e cada UPDATE de coluna indexada move entradas; isso aumenta o tempo de escrita, I/O, uso de buffer pool e armazenamento (veja o último SELECT do script). É preciso equilibrar: indexar o que as consultas realmente usam e remover redundâncias (ex.: `idx_loc_cliente` é prefixo de `idx_loc_cli_data`).

---

# ENTREGÁVEL C — RESUMO PARA APRESENTAÇÃO

- **EXPLAIN:** mostra *como* o MySQL pretende executar (`type`, `key`, `rows`, `Extra`); `EXPLAIN ANALYZE` executa e compara estimativa com realidade.
- **Por que índices ajudam:** trocam varredura completa O(N) por busca em B-tree O(log N). Q1: de ~500 mil linhas lidas para ~10.
- **Seletividade:** fração de linhas retornada por um filtro. Alta seletividade (poucas linhas, ex.: 2%) favorece o índice; baixa (74%) leva a varredura completa.
- **Por que índices são ignorados:** função na coluna (`DATE_FORMAT`), curinga inicial (`LIKE '%x'`), conversão de tipo na coluna (`cpf = 4242`), baixa seletividade, estatísticas.
- **Índice composto:** ordenado por colunas, na ordem declarada; vale a regra do prefixo à esquerda. (id_cliente, data) serve a "cliente" e "cliente + data", mas não a "só data".
- **Escrita:** cada índice é mais uma estrutura a manter em INSERT/UPDATE/DELETE, com custo de tempo e espaço; invisível não significa grátis.

---

## Checklist de completude

Todos os itens do checklist do enunciado estão contemplados no script (blocos Partes 0–5) e neste documento; os campos que dependem de execução real estão marcados "validar" ou com tempo em branco.
