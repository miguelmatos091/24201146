-- =========================================================
-- Banco de dados: aeroporto (versão para o projeto PHP em camadas)
-- Igual ao script original, com UMA diferença: voos.id agora é
-- AUTO_INCREMENT, para que o model Voo::criar() não precise
-- informar o id.
--
-- Se você já tem a tabela criada com os dados, NÃO precisa
-- recriar: basta rodar apenas o comando abaixo.
--   ALTER TABLE voos MODIFY id INT NOT NULL AUTO_INCREMENT;
-- =========================================================

CREATE DATABASE IF NOT EXISTS aeroporto CHARACTER SET utf8mb4;
USE aeroporto;

DROP TABLE IF EXISTS voos;
CREATE TABLE voos (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
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
