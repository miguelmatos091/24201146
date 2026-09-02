-- =========================================================
-- Banco de dados: aeroporto
-- Etapa: REGRAS DE INTEGRIDADE
-- Base: sql_normalizado.sql (modelo apos aplicacao das
-- Formas Normais 1FN-5FN sobre sql_aula_8.sql)
-- =========================================================

CREATE DATABASE IF NOT EXISTS aeroporto;
USE aeroporto;

-- ---------------------------------------------------------
-- Tabela: destinos
-- ---------------------------------------------------------
CREATE TABLE destinos (
    id_destino INT PRIMARY KEY,                 -- integridade de entidade/chave
    cidade VARCHAR(100) NOT NULL UNIQUE          -- obrigatoriedade + unicidade (regra de negocio:
                                                  -- cada cidade so pode ser cadastrada uma vez)
);

-- ---------------------------------------------------------
-- Tabela: voos
-- ---------------------------------------------------------
CREATE TABLE voos (
    id INT PRIMARY KEY,                          -- integridade de entidade/chave

    numero_voo INT NOT NULL UNIQUE               -- obrigatoriedade + unicidade
        CHECK (numero_voo > 0),                  -- dominio: numero de voo nao pode ser <= 0

    id_destino INT NOT NULL,                     -- obrigatoriedade: todo voo precisa de destino

    portao VARCHAR(10),                          -- opcional: pode nao ter sido definido ainda

    horario TIME NOT NULL,                       -- obrigatoriedade + dominio (tipo TIME valida o formato)

    status VARCHAR(20) NOT NULL DEFAULT 'Aguardando'  -- obrigatoriedade + valor padrao
        CHECK (status IN ('Aguardando','Confirmado','Embarque','Cancelado','Pousado')),
                                                  -- dominio: status so pode assumir valores validos
                                                  -- do fluxo operacional do sistema

    CONSTRAINT fk_voos_destino FOREIGN KEY (id_destino)
        REFERENCES destinos (id_destino)
        ON DELETE RESTRICT                       -- regra de negocio: nao permite excluir um destino
                                                   -- enquanto existirem voos vinculados a ele
        ON UPDATE CASCADE                        -- se o id_destino for alterado, propaga a mudanca
                                                   -- para os voos relacionados, evitando FK orfa
);

-- ---------------------------------------------------------
-- Inserindo os dados: destinos
-- ---------------------------------------------------------
INSERT INTO destinos (id_destino, cidade) VALUES
(1, 'Belo Horizonte'),
(2, 'Brasilia'),
(3, 'Curitiba'),
(4, 'Fortaleza'),
(5, 'Porto Alegre'),
(6, 'Recife'),
(7, 'Rio de Janeiro'),
(8, 'Salvador'),
(9, 'Sao Paulo');

-- ---------------------------------------------------------
-- Inserindo os dados: voos
-- ---------------------------------------------------------
INSERT INTO voos (id, numero_voo, id_destino, portao, horario, status) VALUES
(1, 305, 2, '12', '08:30', 'Embarque'),
(2, 420, 7, '08', '09:15', 'Confirmado'),
(3, 711, 9, '23', '10:40', 'Embarque'),
(4, 125, 8, '15', '11:20', 'Confirmado'),
(5, 308, 2, '07', '12:00', 'Aguardando'),
(6, 512, 1, '04', '12:30', 'Embarque'),
(7, 630, 6, '18', '13:10', 'Confirmado'),
(8, 215, 2, '09', '13:45', 'Aguardando'),
(9, 842, 3, '21', '14:00', 'Embarque'),
(10, 391, 7, '06', '14:30', 'Confirmado'),
(11, 527, 8, '14', '15:15', 'Aguardando'),
(12, 104, 2, '03', '15:40', 'Embarque'),
(13, 763, 4, '19', '16:00', 'Confirmado'),
(14, 455, 9, '25', '16:20', 'Aguardando'),
(15, 290, 2, '11', '17:00', 'Confirmado'),
(16, 618, 6, '17', '17:30', 'Embarque'),
(17, 732, 7, '05', '18:00', 'Confirmado'),
(18, 156, 2, '10', '18:20', 'Aguardando'),
(19, 904, 5, '22', '19:00', 'Embarque'),
(20, 347, 9, '24', '19:30', 'Confirmado'),
(21, 681, 2, '13', '20:00', 'Embarque'),
(22, 219, 8, '16', '20:30', 'Aguardando'),
(23, 573, 1, '02', '21:00', 'Confirmado'),
(24, 806, 2, '01', '21:30', 'Embarque'),
(25, 438, 7, '07', '22:00', 'Confirmado'),
(26, 927, 6, '20', '22:30', 'Aguardando'),
(27, 314, 2, '06', '23:00', 'Embarque'),
(28, 569, 3, '26', '23:20', 'Confirmado'),
(29, 781, 9, '27', '23:40', 'Aguardando'),
(30, 650, 2, '05', '23:55', 'Confirmado');

-- ---------------------------------------------------------
-- Consulta de verificacao
-- ---------------------------------------------------------
SELECT v.id, v.numero_voo, d.cidade AS destino, v.portao, v.horario, v.status
FROM voos v
JOIN destinos d ON d.id_destino = v.id_destino;

-- =========================================================
-- TESTES DAS REGRAS DE INTEGRIDADE
-- (comandos comentados; descomentar um de cada vez para
-- reproduzir os testes documentados em integridade.md)
-- =========================================================

-- Teste 1: PK duplicada em voos.id
-- INSERT INTO voos VALUES (1, 999, 2, '20', '07:00', 'Confirmado');

-- Teste 2: numero_voo duplicado (violacao de UNIQUE)
-- INSERT INTO voos VALUES (31, 305, 2, '20', '07:00', 'Confirmado');

-- Teste 3: id_destino NULL (violacao de NOT NULL)
-- INSERT INTO voos VALUES (31, 999, NULL, '20', '07:00', 'Confirmado');

-- Teste 4: id_destino inexistente (violacao de integridade referencial)
-- INSERT INTO voos VALUES (31, 999, 50, '20', '07:00', 'Confirmado');

-- Teste 5: status fora do dominio permitido (violacao de CHECK)
-- INSERT INTO voos VALUES (31, 999, 2, '20', '07:00', 'Atrasado');

-- Teste 6: numero_voo negativo (violacao de CHECK)
-- INSERT INTO voos VALUES (31, -10, 2, '20', '07:00', 'Confirmado');

-- Teste 7: exclusao de destino com voos vinculados (ON DELETE RESTRICT)
-- DELETE FROM destinos WHERE id_destino = 2;

-- Teste 8: cidade duplicada em destinos (violacao de UNIQUE)
-- INSERT INTO destinos VALUES (10, 'Brasilia');

-- Teste 9 (controle positivo): insercao valida
-- INSERT INTO voos VALUES (31, 999, 4, '20', '07:00', 'Confirmado');

-- Teste 10: insercao sem informar status (usa DEFAULT 'Aguardando')
-- INSERT INTO voos (id, numero_voo, id_destino, portao, horario) VALUES (32, 1000, 4, '21', '06:00');
