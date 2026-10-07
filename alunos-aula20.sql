-- 1) Banco e tabela
CREATE DATABASE IF NOT EXISTS escola CHARACTER SET utf8mb4;
USE escola;

CREATE TABLE IF NOT EXISTS alunos (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nota DECIMAL(4,2) NOT NULL,
    CONSTRAINT chk_nota CHECK (nota BETWEEN 0 AND 10)
);

-- 2) Registros (aprovados e reprovados)
INSERT INTO alunos (nome, nota) VALUES
('Ana Souza',       8.5),
('Bruno Lima',      6.0),
('Carlos Mendes',   7.0),
('Daniel Oliveira', 5.5),
('Eduarda Santos',  9.0),
('Fernanda Rocha',  6.9);
