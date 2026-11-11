# Entrega — migrations do aeroporto
- `migrate.php`, `migrations/`, `backfill_destino.php`: runner, 4 migrations e backfill
- `schema_migrations.txt`: tabela de controle após aplicar tudo
- `respostas.md`: Perguntas 1 e 2 e Parte 4
- `aplicacao/`: projeto do aeroporto já atualizado (lê e grava `aeroporto_destino`)
- `Voo.fase3_dupla_escrita.php`: model na fase intermediária do passo 3 (grava nas duas colunas)

Uso: `php migrate.php up | down`; backfill: `php backfill_destino.php` (banco `aeroporto_lab`;
configurável com DB_HOST, DB_NAME, DB_USER, DB_PASS).
Ordem do laboratório: 001–002 → 003 → backfill → trocar código (dupla escrita, depois só a coluna nova) → 004.
