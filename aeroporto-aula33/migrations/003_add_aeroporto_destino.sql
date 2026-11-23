-- 003_add_aeroporto_destino.sql
-- Passo 1 (EXPANDIR): adapta o exemplo origem -> aeroporto_origem para
-- destino -> aeroporto_destino, pois `voos` não tem a coluna `origem`.
-- up
ALTER TABLE voos ADD COLUMN aeroporto_destino VARCHAR(100) NULL;

-- down
ALTER TABLE voos DROP COLUMN aeroporto_destino;
