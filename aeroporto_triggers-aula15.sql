-- =========================================================
-- Atividade Prática: Automação e Integridade com Triggers
-- Disciplina: Banco de Dados II
-- Tema: Triggers (BEFORE/AFTER, INSERT/UPDATE/DELETE, NEW/OLD)
-- Contexto: Sistema de Gestão Aeroportuária
--
-- Aluno: Miguel Matos
-- Banco de dados: aeroporto
--
-- Descrição sintética das tabelas utilizadas:
--   voos           -> tabela original do modelo individual, com os
--                     dados de cada voo (numero, destino, portao,
--                     horario, status).
--   portoes        -> tabela adicionada para permitir a checagem de
--                     disponibilidade de infraestrutura (Desafio 1)
--                     e a sincronização automática de status
--                     (Desafio 3), já que o modelo original não
--                     possuía uma entidade separada para portões.
--   log_alteracao_voo -> tabela de auditoria criada para o Desafio 2,
--                     registrando alterações de status/portão em
--                     um voo (valor antigo, valor novo, data/hora
--                     e usuário do SGBD responsável).
-- =========================================================

CREATE DATABASE IF NOT EXISTS aeroporto;
USE aeroporto;

-- ---------------------------------------------------------
-- Tabela: voos (modelo original)
-- ---------------------------------------------------------
DROP TABLE IF EXISTS voos;
CREATE TABLE voos (
    id INT PRIMARY KEY,
    numero_voo INT NOT NULL,
    destino VARCHAR(100) NOT NULL,
    portao VARCHAR(10),
    horario TIME NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO voos (id, numero_voo, destino, portao, horario, status) VALUES
(1, 305, 'Brasilia', '12', '08:30', 'Embarque'),
(2, 420, 'Rio de Janeiro', '08', '09:15', 'Confirmado'),
(3, 711, 'Sao Paulo', '23', '10:40', 'Embarque'),
(4, 125, 'Salvador', '15', '11:20', 'Confirmado'),
(5, 308, 'Brasilia', '07', '12:00', 'Aguardando'),
(6, 512, 'Belo Horizonte', '04', '12:30', 'Embarque'),
(7, 630, 'Recife', '18', '13:10', 'Confirmado'),
(8, 215, 'Brasilia', '09', '13:45', 'Aguardando'),
(9, 842, 'Curitiba', '21', '14:00', 'Embarque'),
(10, 391, 'Rio de Janeiro', '06', '14:30', 'Confirmado'),
(11, 527, 'Salvador', '14', '15:15', 'Aguardando'),
(12, 104, 'Brasilia', '03', '15:40', 'Embarque'),
(13, 763, 'Fortaleza', '19', '16:00', 'Confirmado'),
(14, 455, 'Sao Paulo', '25', '16:20', 'Aguardando'),
(15, 290, 'Brasilia', '11', '17:00', 'Confirmado'),
(16, 618, 'Recife', '17', '17:30', 'Embarque'),
(17, 732, 'Rio de Janeiro', '05', '18:00', 'Confirmado'),
(18, 156, 'Brasilia', '10', '18:20', 'Aguardando'),
(19, 904, 'Porto Alegre', '22', '19:00', 'Embarque'),
(20, 347, 'Sao Paulo', '24', '19:30', 'Confirmado'),
(21, 681, 'Brasilia', '13', '20:00', 'Embarque'),
(22, 219, 'Salvador', '16', '20:30', 'Aguardando'),
(23, 573, 'Belo Horizonte', '02', '21:00', 'Confirmado'),
(24, 806, 'Brasilia', '01', '21:30', 'Embarque'),
(25, 438, 'Rio de Janeiro', '07', '22:00', 'Confirmado'),
(26, 927, 'Recife', '20', '22:30', 'Aguardando'),
(27, 314, 'Brasilia', '06', '23:00', 'Embarque'),
(28, 569, 'Curitiba', '26', '23:20', 'Confirmado'),
(29, 781, 'Sao Paulo', '27', '23:40', 'Aguardando'),
(30, 650, 'Brasilia', '05', '23:55', 'Confirmado');

-- ---------------------------------------------------------
-- Tabela: portoes (entidade adicionada ao modelo)
-- ---------------------------------------------------------
DROP TABLE IF EXISTS portoes;
CREATE TABLE portoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(10) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'LIVRE'  -- LIVRE, OCUPADO, MANUTENCAO
);

-- Populamos com todos os portões já usados em "voos", todos como LIVRE.
-- (o status real será ajustado pelos próprios triggers a partir daqui)
INSERT INTO portoes (numero, status)
SELECT DISTINCT portao, 'LIVRE' FROM voos WHERE portao IS NOT NULL;

-- Colocamos um portão propositalmente em manutenção, para os testes do Desafio 1
UPDATE portoes SET status = 'MANUTENCAO' WHERE numero = '99';
INSERT INTO portoes (numero, status) VALUES ('99', 'MANUTENCAO');

-- ---------------------------------------------------------
-- Tabela: log_alteracao_voo (auditoria - Desafio 2)
-- ---------------------------------------------------------
DROP TABLE IF EXISTS log_alteracao_voo;
CREATE TABLE log_alteracao_voo (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_voo INT NOT NULL,
    campo_alterado VARCHAR(50) NOT NULL,
    valor_anterior VARCHAR(100),
    valor_novo VARCHAR(100),
    data_hora_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_sgbd VARCHAR(100)
);

-- =========================================================
-- DESAFIO 1: Validação de Regra de Negócio Operacional
-- BEFORE INSERT em voos
-- Regra: não permitir cadastrar um voo em um portão cujo status
-- não seja LIVRE nem OPERACIONAL (ex.: em MANUTENCAO).
-- =========================================================
DELIMITER $$

CREATE TRIGGER trg_voos_before_insert
BEFORE INSERT ON voos
FOR EACH ROW
BEGIN
    DECLARE v_status_portao VARCHAR(20);

    SELECT status INTO v_status_portao
    FROM portoes
    WHERE numero = NEW.portao
    LIMIT 1;

    IF v_status_portao IS NOT NULL
       AND v_status_portao NOT IN ('LIVRE', 'OPERACIONAL') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Portao indisponivel: nao e possivel alocar um voo em portao que nao esta LIVRE ou OPERACIONAL.';
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- DESAFIO 2: Auditoria e Rastreabilidade de Modificações
-- AFTER UPDATE em voos
-- Regra: registrar em log_alteracao_voo toda mudança de
-- status ou de portão, usando OLD e NEW.
-- =========================================================
DELIMITER $$

CREATE TRIGGER trg_voos_after_update_auditoria
AFTER UPDATE ON voos
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO log_alteracao_voo (id_voo, campo_alterado, valor_anterior, valor_novo, usuario_sgbd)
        VALUES (NEW.id, 'status', OLD.status, NEW.status, CURRENT_USER());
    END IF;

    IF OLD.portao <> NEW.portao THEN
        INSERT INTO log_alteracao_voo (id_voo, campo_alterado, valor_anterior, valor_novo, usuario_sgbd)
        VALUES (NEW.id, 'portao', OLD.portao, NEW.portao, CURRENT_USER());
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- DESAFIO 3: Sincronização Automática de Dados em Cascata
-- AFTER INSERT e AFTER DELETE em voos
-- Regra: quando um voo com status 'Embarque' e inserido, o
-- portao correspondente passa a OCUPADO; quando o voo e
-- removido, o portao volta a ficar LIVRE.
-- =========================================================
DELIMITER $$

CREATE TRIGGER trg_voos_after_insert_sync_portao
AFTER INSERT ON voos
FOR EACH ROW
BEGIN
    IF NEW.status = 'Embarque' AND NEW.portao IS NOT NULL THEN
        UPDATE portoes
        SET status = 'OCUPADO'
        WHERE numero = NEW.portao;
    END IF;
END$$

CREATE TRIGGER trg_voos_after_delete_sync_portao
AFTER DELETE ON voos
FOR EACH ROW
BEGIN
    IF OLD.portao IS NOT NULL THEN
        UPDATE portoes
        SET status = 'LIVRE'
        WHERE numero = OLD.portao;
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- ROTEIRO DE VALIDAÇÃO E TESTES
-- =========================================================

-- ---------------------------------------------------------
-- 4.1 Teste do Desafio 1 (gatilho de validação)
-- ---------------------------------------------------------

-- Caso INVALIDO: portao '99' esta em MANUTENCAO -> deve ser bloqueado
-- Resultado esperado: erro SQLSTATE 45000
INSERT INTO voos (id, numero_voo, destino, portao, horario, status)
VALUES (31, 999, 'Manaus', '99', '06:00', 'Confirmado');

-- Caso VALIDO: portao '08' esta LIVRE -> deve ser aceito
INSERT INTO voos (id, numero_voo, destino, portao, horario, status)
VALUES (32, 998, 'Manaus', '08', '06:10', 'Confirmado');

SELECT * FROM voos WHERE id = 32;

-- ---------------------------------------------------------
-- 4.2 Teste do Desafio 2 (gatilho de auditoria)
-- ---------------------------------------------------------

-- Alteramos o status do voo 32 (dispara o AFTER UPDATE)
UPDATE voos SET status = 'Embarque' WHERE id = 32;

-- Conferimos o log gerado
SELECT * FROM log_alteracao_voo WHERE id_voo = 32;

-- ---------------------------------------------------------
-- 4.3 Teste do Desafio 3 (gatilho de sincronizacao)
-- ---------------------------------------------------------

-- Estado do portao ANTES do impacto indireto
SELECT * FROM portoes WHERE numero = '08';

-- Inserimos um novo voo em status 'Embarque' no portao '08'
-- (o UPDATE acima ja deixou o voo 32 em Embarque no portao 08,
--  entao aqui confirmamos que o AFTER INSERT tambem sincroniza
--  ao cadastrar outro voo em Embarque em um portao ainda livre)
INSERT INTO voos (id, numero_voo, destino, portao, horario, status)
VALUES (33, 997, 'Belem', '17', '06:20', 'Embarque');

SELECT * FROM portoes WHERE numero = '17';
-- Resultado esperado: status = 'OCUPADO'

-- Removemos o voo e conferimos que o portao volta a ficar LIVRE
DELETE FROM voos WHERE id = 33;

SELECT * FROM portoes WHERE numero = '17';
-- Resultado esperado: status = 'LIVRE'
