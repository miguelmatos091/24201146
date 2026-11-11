-- Aula 23: dados de teste para o laboratório de SQL Injection (somente no banco local).
-- Os "hashes" abaixo são FALSOS, só para o payload 4 ter o que mostrar.
USE aeroporto;

DROP TABLE IF EXISTS usuarios;
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL
);

INSERT INTO usuarios (nome, email, senha_hash) VALUES
('Usuario Teste 1', 'teste1@exemplo.com', 'hash_falso_001'),
('Usuario Teste 2', 'teste2@exemplo.com', 'hash_falso_002'),
('Usuario Teste 3', 'teste3@exemplo.com', 'hash_falso_003');
