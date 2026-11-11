-- =========================================================
-- Aula 24 - Privilégios: conta mínima para a aplicação
-- Rode como ADMINISTRADOR:  mysql -u root -p < database/privilegios.sql
-- (as migrations de estrutura, como ALTER TABLE, continuam sendo
--  rodadas como root; a aplicação não precisa desse poder)
-- =========================================================

-- PARTE 1: conta da aplicação (TROQUE a senha pela sua e use a mesma em DB_PASS)
CREATE USER IF NOT EXISTS 'app_aeroporto'@'localhost'
  IDENTIFIED BY 'SenhaForte#123';

-- CRUD de voos. O soft delete é um UPDATE, então não precisa de DELETE.
GRANT SELECT, INSERT, UPDATE
  ON aeroporto.voos
  TO 'app_aeroporto'@'localhost';

-- Auditoria do soft delete (Aula 21): só leitura e inserção. Sem UPDATE/DELETE,
-- a aplicação não consegue alterar nem apagar o histórico.
GRANT SELECT, INSERT
  ON aeroporto.auditoria
  TO 'app_aeroporto'@'localhost';

-- Aula 25: o login precisa LER a tabela de usuários da aplicação. Só SELECT:
-- a conta não consegue criar, alterar nem apagar usuários.
GRANT SELECT
  ON aeroporto.usuarios
  TO 'app_aeroporto'@'localhost';

-- (Antes da Aula 25 não havia nenhum GRANT em `usuarios`; nas demais tabelas que
--  a aplicação não usa, continuamos sem conceder nada.)

SHOW GRANTS FOR 'app_aeroporto'@'localhost';

-- =========================================================
-- TESTE (terminal, com a conta nova):  mysql -u app_aeroporto -p aeroporto
-- =========================================================
-- DELETE FROM voos WHERE id = 1;   -- ERROR 1142 (42000): DELETE command denied ...
-- DROP TABLE voos;                 -- ERROR 1142 (42000): DROP command denied ...
-- SELECT * FROM usuarios;          -- (Aula 24) negado; desde a Aula 25 o SELECT é permitido

-- =========================================================
-- DESAFIO: conta só de leitura (como root)
-- Adaptação: o esquema do projeto não tem `passageiros` nem CPF. Usei a
-- coluna `portao` de `voos` como a coluna "sensível" a esconder.
-- =========================================================
-- CREATE USER 'relatorios'@'localhost' IDENTIFIED BY 'OutraSenha#456';
-- GRANT SELECT ON aeroporto.* TO 'relatorios'@'localhost';
--
-- Item 1 (como relatorios):
--   INSERT INTO voos (numero_voo, destino, horario, status)
--   VALUES (1, 'Teste', '10:00', 'Aguardando');
--   -- ERROR 1142 (42000): INSERT command denied ...
--
-- Item 2: restringir por coluna (como root)
-- REVOKE SELECT ON aeroporto.* FROM 'relatorios'@'localhost';
-- GRANT SELECT (id, numero_voo, destino, horario, status)
--   ON aeroporto.voos TO 'relatorios'@'localhost';
--
-- Item 3 (como relatorios):
--   SELECT portao FROM voos;
--   -- ERROR 1143 (42000): SELECT command denied ... for column 'portao' ...
--   (SELECT * FROM voos também falha, pois inclui `portao`.)
--
-- Item 4: alternativa com VIEW (como root). Já filtra os voos excluídos.
-- REVOKE SELECT (id, numero_voo, destino, horario, status)
--   ON aeroporto.voos FROM 'relatorios'@'localhost';
-- CREATE OR REPLACE VIEW vw_voos_relatorio AS
--   SELECT id, numero_voo, destino, horario, status
--   FROM voos WHERE deleted_at IS NULL;
-- GRANT SELECT ON aeroporto.vw_voos_relatorio TO 'relatorios'@'localhost';
--
-- Limpeza (como root):
-- DROP USER 'relatorios'@'localhost';
-- Mantenha app_aeroporto: ela será usada nas próximas aulas.
