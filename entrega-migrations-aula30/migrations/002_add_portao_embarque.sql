-- 002_add_portao_embarque.sql
-- up
ALTER TABLE voos ADD COLUMN portao_embarque VARCHAR(5) NULL;

-- down
ALTER TABLE voos DROP COLUMN portao_embarque;
