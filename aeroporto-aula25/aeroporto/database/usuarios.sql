-- =========================================================
-- Aula 25: usuários da APLICAÇÃO (login do sistema)
-- Rode como ADMINISTRADOR do MySQL:  mysql -u root -p < database/usuarios.sql
--
-- ATENÇÃO: o DROP abaixo substitui a tabela `usuarios` de teste da Aula 23
-- (que tinha a coluna `nome` e hashes falsos). Se você tem dados reais nela,
-- não rode o DROP.
-- =========================================================
USE aeroporto;

DROP TABLE IF EXISTS usuarios;
CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(120) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  perfil VARCHAR(20) NOT NULL DEFAULT 'operador'
);

-- Usuários de teste. A senha dos dois é: senha123
-- (o hash abaixo é o resultado de password_hash('senha123', PASSWORD_DEFAULT);
--  para gerar outro: php -r "echo password_hash('SUA_SENHA', PASSWORD_DEFAULT);")
INSERT INTO usuarios (email, senha_hash, perfil) VALUES
('operador@aeroporto.com', '$2y$10$yh6V4MHK1KOyiXQ8v9mUwuwCNrP5SKgUtkHPB3JZsVIWt0/RuQH9K', 'operador'),
('admin@aeroporto.com',    '$2y$10$yh6V4MHK1KOyiXQ8v9mUwuwCNrP5SKgUtkHPB3JZsVIWt0/RuQH9K', 'admin');
