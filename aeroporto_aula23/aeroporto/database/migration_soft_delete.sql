-- =========================================================
-- Migration: Soft Delete de voos + tabela de auditoria
-- Rode UMA vez, no banco `aeroporto`.
-- =========================================================
USE aeroporto;

-- 1) Coluna de exclusão lógica (NULL = voo ativo)
ALTER TABLE voos
  ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL;

-- 2) Índice: as listagens filtram por deleted_at
CREATE INDEX idx_voos_deleted_at ON voos (deleted_at);

-- 3) Auditoria (quem fez o quê e quando; dados_antes guarda a linha original)
CREATE TABLE auditoria (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  tabela      VARCHAR(50),
  registro_id INT,
  acao        VARCHAR(20),
  usuario_id  INT,
  dados_antes JSON,
  criado_em   DATETIME DEFAULT NOW()
);

-- Observação: `voos` não tem índice único em numero_voo. Se tivesse, o
-- recomendado seria UNIQUE (numero_voo, deleted_at), mas como NULL não
-- colide em UNIQUE no MySQL, o ideal é uma coluna gerada, por exemplo:
--   ALTER TABLE voos ADD COLUMN ativo_chave INT
--     GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) STORED,
--     ADD UNIQUE (numero_voo, ativo_chave);
