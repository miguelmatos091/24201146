-- =========================================================
-- Banco de dados: aeroporto (MODELO NORMALIZADO)
-- Resultado da aplicacao das Formas Normais (1FN a 5FN)
-- sobre o SQL da Aula 8 (sql_aula_8.sql)
-- =========================================================

CREATE DATABASE IF NOT EXISTS aeroporto;
USE aeroporto;

-- ---------------------------------------------------------
-- Tabela: destinos
-- Extraida da tabela "voos" para eliminar a dependencia
-- transitiva id -> numero_voo -> destino (violacao de 3FN)
-- e a redundancia de texto repetido (ex.: "Brasilia" 10x).
-- ---------------------------------------------------------
CREATE TABLE destinos (
    id_destino INT PRIMARY KEY,
    cidade VARCHAR(100) NOT NULL UNIQUE
);

-- ---------------------------------------------------------
-- Tabela: voos
-- Mantem apenas os atributos com dependencia funcional
-- direta e nao-transitiva em relacao a chave primaria (id).
-- ---------------------------------------------------------
CREATE TABLE voos (
    id INT PRIMARY KEY,
    numero_voo INT NOT NULL UNIQUE,
    id_destino INT NOT NULL,
    portao VARCHAR(10),
    horario TIME NOT NULL,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_voos_destino FOREIGN KEY (id_destino)
        REFERENCES destinos (id_destino)
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
-- Consultas de exemplo
-- ---------------------------------------------------------
SELECT v.id, v.numero_voo, d.cidade AS destino, v.portao, v.horario, v.status
FROM voos v
JOIN destinos d ON d.id_destino = v.id_destino;

-- SELECT * FROM voos WHERE status = 'Embarque';
-- SELECT * FROM destinos WHERE cidade = 'Brasilia';
-- SELECT COUNT(*) AS total_voos FROM voos;
