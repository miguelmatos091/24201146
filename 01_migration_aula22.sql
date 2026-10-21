-- Migration: soft delete em voos + tabela de auditoria
USE aeroporto;

ALTER TABLE voos
  ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL,
  ADD INDEX idx_voos_deleted_at (deleted_at);

CREATE TABLE IF NOT EXISTS auditoria (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  tabela      VARCHAR(50),
  registro_id INT,
  acao        VARCHAR(20),
  usuario_id  INT,
  dados_antes JSON,
  criado_em   DATETIME DEFAULT NOW()
);

-- Desafio extra: se numero_voo tiver índice único, troque por um composto
-- (descomente e ajuste o nome do índice existente):
-- ALTER TABLE voos DROP INDEX numero_voo;
-- ALTER TABLE voos ADD COLUMN ativo_chave TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) STORED,
--   ADD UNIQUE KEY uq_numero_voo_ativo (numero_voo, ativo_chave);
