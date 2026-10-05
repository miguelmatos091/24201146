# Entrega — Views e Índices (Projeto Aeroporto)

> Schema usado: `aeroportos`, `companhias`, `voos`, `passageiros`, `reservas` (ver `aeroporto_views_indices.sql`).
> Se o seu banco é diferente, adapte os nomes; o método é o mesmo.

## Etapa 1 — Diagnóstico

**Relacionamentos:** `voos` → `companhias`, `voos` → `aeroportos` (origem e destino), `reservas` → `voos` e `passageiros`.

**Consultas repetidas (candidatas a view):**
1. Listar voos com companhia, origem e destino (3 JOINs toda vez).
2. Contar reservas confirmadas por voo para ver a ocupação.
3. Listar só voos agendados/atrasados.
4. Buscar voos atrasados (`WHERE status = 'atrasado'`).

**Colunas mais usadas em WHERE/JOIN:** `voos.status`, `voos.data_partida`, `reservas.voo_id`.

## Etapa 2 — Formulários de proposta de view

**View 1**
```
Nome da view: vw_voos_detalhados
Tabelas de origem: voos, companhias, aeroportos (2x)
Tipo: JOIN
É atualizável? Não: junta várias tabelas, e aeroportos aparece duas vezes.
Problema que resolve: evita reescrever 3 JOINs e mostra nomes em vez de IDs.
```
**View 2**
```
Nome da view: vw_ocupacao_voo
Tabelas de origem: voos, reservas
Tipo: agregação (COUNT + GROUP BY)
É atualizável? Não: usa agregação.
Problema que resolve: painel de ocupação (% de assentos reservados) por voo.
```
**View 3 (extra)**
```
Nome da view: vw_voos_ativos
Tabelas de origem: voos
Tipo: simples, com filtro fixo
É atualizável? Sim: uma tabela, sem agregação. WITH CHECK OPTION impede que
um UPDATE/INSERT faça o voo "sumir" da view (ex.: status = 'concluido').
Problema que resolve: a equipe de operação só enxerga voos em andamento.
```
Código (já no `.sql`): `CREATE VIEW vw_voos_detalhados`, `vw_ocupacao_voo`, `vw_voos_ativos ... WITH CHECK OPTION`.

**Validação real (SQLite, 200 mil voos / 30 mil reservas):** as 3 views executaram sem erro e retornaram 200.000, 200.000 e 123.881 linhas, com ocupação calculada corretamente (ex.: voo 1 → 13 reservas, 7,2%).

## Etapa 3/4 — Índice testado: `idx_voos_status`

Consulta: `SELECT * FROM voos WHERE status = 'atrasado';` (≈2% das linhas)

### Resultado medido por mim (SQLite, 200.000 linhas, média de 20 execuções)

| Consulta | plano antes | tempo antes | plano depois | tempo depois | Conclusão |
|---|---|---|---|---|---|
| `status = 'atrasado'` | `SCAN voos` (varredura completa) | 13,99 ms | `SEARCH ... USING INDEX idx_voos_status` | 5,74 ms | ~2,4x mais rápido; coluna seletiva |

### Resultado no MySQL (preencher após rodar o `.sql` no seu servidor)

| Consulta testada | `type` antes | `rows` antes | tempo médio antes (ms) | `type` depois | `rows` depois | tempo médio depois (ms) | Conclusão |
|---|---|---|---|---|---|---|---|
| `status='atrasado'` | _ALL esperado_ | _~200.000_ | ____ | _ref esperado_ | _~4.000_ | ____ | ____ |

Valores em itálico são o **esperado**, não medição. Os campos `____` precisam dos seus números reais do `performance_schema`.

### Conclusão (modelo)
O índice ajudou porque `status = 'atrasado'` é **seletivo** (~2% das linhas): o banco deixou de ler a tabela inteira. Vale manter, pois status muda pouco por voo e o custo extra em `INSERT`/`UPDATE` é pequeno. Em contraste, `status = 'agendado'` (60% das linhas) é de baixa seletividade, e o MySQL pode ignorar o índice e preferir a varredura completa. Por isso, a decisão de criar índice depende da **seletividade da coluna**, não só de ela aparecer no WHERE.

## Etapa 5 — Para compartilhar com a turma
- **View:** `vw_voos_ativos` com `WITH CHECK OPTION`, porque protege a regra de negócio na própria view.
- **Índice:** ganho claro em coluna seletiva; ganho nulo em coluna de baixa seletividade.

## O que entregar
- [x] Formulários de view (3)
- [x] Registro de índice (SQLite medido; MySQL a preencher)
- [x] `CREATE VIEW` e `CREATE INDEX` em `aeroporto_views_indices.sql`
