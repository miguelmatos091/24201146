-- 003_add_aeroporto_destino.sql
-- ADAPTAÇÃO: a tabela voos do projeto não tem `origem`; o renome feito aqui é
-- destino -> aeroporto_destino (passo "expandir").
-- Uma única instrução: cria a coluna nova E afrouxa o NOT NULL de `destino`,
-- para que o código novo possa deixar de gravar `destino` antes do passo 4.
-- up
ALTER TABLE voos ADD COLUMN aeroporto_destino VARCHAR(100) NULL, MODIFY destino VARCHAR(100) NULL;

-- down
-- (só funciona se nenhuma linha tiver destino NULL; ver respostas.md)
ALTER TABLE voos DROP COLUMN aeroporto_destino, MODIFY destino VARCHAR(100) NOT NULL;
