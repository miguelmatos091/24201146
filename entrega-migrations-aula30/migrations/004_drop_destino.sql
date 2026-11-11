-- 004_drop_destino.sql
-- Passo "contrair": só aplicar depois que TODO o código lê e grava aeroporto_destino.
-- up
ALTER TABLE voos DROP COLUMN destino;

-- down
-- Recria a coluna VAZIA (e NULL, pois já há linhas). Os dados NÃO voltam:
-- recupere-os com UPDATE voos SET destino = aeroporto_destino.
ALTER TABLE voos ADD COLUMN destino VARCHAR(100) NULL;
