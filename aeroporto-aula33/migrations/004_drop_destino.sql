-- 004_drop_destino.sql
-- Passo 4 (CONTRAIR): só aplicar depois que o código novo (que usa apenas
-- aeroporto_destino) estiver funcionando. O down recria a coluna VAZIA.
-- up
ALTER TABLE voos DROP COLUMN destino;

-- down
ALTER TABLE voos ADD COLUMN destino VARCHAR(100) NULL;
