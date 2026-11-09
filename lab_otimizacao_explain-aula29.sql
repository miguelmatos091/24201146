-- =====================================================================
-- ATIVIDADE: LENDO O PLANO DE EXECUCAO COM EXPLAIN (MySQL 8.0.18+)
-- Banco: lab_otimizacao | Tema: locadora de carros
-- Execute BLOCO A BLOCO e anote os resultados reais de cada EXPLAIN.
-- Os indices sao criados progressivamente; nao inverta a ordem.
-- =====================================================================


-- =====================================================================
-- PARTE 0 - PREPARACAO
-- =====================================================================
DROP DATABASE IF EXISTS lab_otimizacao;
CREATE DATABASE lab_otimizacao;
USE lab_otimizacao;

CREATE TABLE cliente (
  id INT PRIMARY KEY,
  nome VARCHAR(60) NOT NULL,
  cpf VARCHAR(11) NOT NULL,
  cidade VARCHAR(30) NOT NULL
);

CREATE TABLE locacao (
  id INT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_veiculo INT NOT NULL,
  data_retirada DATE NOT NULL,
  valor DECIMAL(8,2) NOT NULL,
  status VARCHAR(10) NOT NULL
);

SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO cliente (id, nome, cpf, cidade)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 50000
)
SELECT n,
       CONCAT('Cliente ', n),
       LPAD(n, 11, '0'),
       ELT(1 + n % 5, 'Brasilia', 'Goiania', 'Anapolis',
           'Taguatinga', 'Gama')
FROM seq;

INSERT INTO locacao (id, id_cliente, id_veiculo, data_retirada, valor, status)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 500000
)
SELECT n,
       1 + (n * 7919) % 50000,
       1 + (n * 31) % 200,
       DATE_ADD('2023-01-01', INTERVAL n % 1095 DAY),
       100 + n % 400,
       CASE
         WHEN n % 50 = 0 THEN 'cancelada'
         WHEN n % 4 = 0 THEN 'aberta'
         ELSE 'concluida'
       END
FROM seq;

ANALYZE TABLE cliente, locacao;

-- Validacoes da Parte 0
SHOW DATABASES LIKE 'lab_otimizacao';
SHOW TABLES;
SELECT COUNT(*) AS total_clientes FROM cliente;   -- esperado: 50000
SELECT COUNT(*) AS total_locacoes FROM locacao;   -- esperado: 500000
SELECT status, COUNT(*) AS qtd,
       ROUND(100 * COUNT(*) / 500000, 1) AS pct
FROM locacao GROUP BY status;                     -- esperado: 10000 / 120000 / 370000
SHOW INDEX FROM cliente;                          -- somente PRIMARY
SHOW INDEX FROM locacao;                          -- somente PRIMARY


-- =====================================================================
-- PARTE 1 - DIAGNOSTICO SEM INDICES SECUNDARIOS
-- =====================================================================

-- Q1
EXPLAIN
SELECT *
FROM locacao
WHERE id_cliente = 4242;

-- Q2
EXPLAIN
SELECT c.nome, l.data_retirada, l.valor
FROM cliente c
JOIN locacao l ON l.id_cliente = c.id
WHERE c.cpf = '00000004242';

-- EXPLAIN ANALYZE de Q1 (anote "actual time" e "rows" reais -> tempo ANTES)
EXPLAIN ANALYZE
SELECT *
FROM locacao
WHERE id_cliente = 4242;


-- =====================================================================
-- PARTE 2 - CRIANDO INDICES E COMPARANDO
-- =====================================================================
CREATE INDEX idx_loc_cliente ON locacao(id_cliente);
CREATE INDEX idx_cli_cpf ON cliente(cpf);

ANALYZE TABLE cliente, locacao;

EXPLAIN
SELECT *
FROM locacao
WHERE id_cliente = 4242;

EXPLAIN
SELECT c.nome, l.data_retirada, l.valor
FROM cliente c
JOIN locacao l ON l.id_cliente = c.id
WHERE c.cpf = '00000004242';

-- tempo DEPOIS
EXPLAIN ANALYZE
SELECT *
FROM locacao
WHERE id_cliente = 4242;

-- 2.1 Seletividade
CREATE INDEX idx_loc_status ON locacao(status);

ANALYZE TABLE locacao;

EXPLAIN
SELECT * FROM locacao
WHERE status = 'cancelada';

EXPLAIN
SELECT * FROM locacao
WHERE status = 'concluida';

-- Complemento (opcional): cardinalidade e distribuicao reais
SHOW INDEX FROM locacao;
SELECT status, COUNT(*) AS qtd,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM locacao), 1) AS pct
FROM locacao GROUP BY status;


-- =====================================================================
-- PARTE 3 - INDICES QUE O MYSQL IGNORA
-- =====================================================================
CREATE INDEX idx_loc_data ON locacao(data_retirada);
CREATE INDEX idx_cli_nome ON cliente(nome);

ANALYZE TABLE cliente, locacao;

-- Caso 3A: funcao na coluna (ANTES)
EXPLAIN
SELECT *
FROM locacao
WHERE DATE_FORMAT(data_retirada, '%Y-%m') = '2025-06';

-- Caso 3A: faixa sargable (DEPOIS) - inicio inclusivo, fim exclusivo
EXPLAIN
SELECT *
FROM locacao
WHERE data_retirada >= '2025-06-01'
  AND data_retirada <  '2025-07-01';

-- Caso 3B: curinga no inicio (ANTES)
EXPLAIN
SELECT *
FROM cliente
WHERE nome LIKE '%123';

-- Caso 3B: prefixo fixo (DEPOIS)
EXPLAIN
SELECT *
FROM cliente
WHERE nome LIKE 'Cliente 123%';

-- Caso 3C: comparacao string x numero (ANTES)
EXPLAIN
SELECT *
FROM cliente
WHERE cpf = 4242;

-- Caso 3C: literal no tipo da coluna (DEPOIS)
EXPLAIN
SELECT *
FROM cliente
WHERE cpf = '00000004242';

-- Para ver como o MySQL reescreveu a condicao do caso 3C (ver SHOW WARNINGS):
EXPLAIN SELECT * FROM cliente WHERE cpf = 4242;
SHOW WARNINGS;


-- =====================================================================
-- PARTE 4 - INDICE COMPOSTO
-- =====================================================================
CREATE INDEX idx_loc_cli_data
ON locacao(id_cliente, data_retirada);

ANALYZE TABLE locacao;

-- Consulta A
EXPLAIN
SELECT *
FROM locacao
WHERE id_cliente = 4242
AND data_retirada >= '2025-01-01';

-- Consulta B
EXPLAIN
SELECT *
FROM locacao
WHERE data_retirada >= '2025-06-01'
AND data_retirada < '2025-07-01';

-- 4.1 Desafio: indice invisivel
ALTER TABLE locacao
ALTER INDEX idx_loc_data INVISIBLE;

-- Confirma a visibilidade (coluna IS_VISIBLE = NO)
SELECT INDEX_NAME, IS_VISIBLE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'lab_otimizacao' AND TABLE_NAME = 'locacao'
GROUP BY INDEX_NAME, IS_VISIBLE;

-- Consulta B sem idx_loc_data visivel
EXPLAIN
SELECT *
FROM locacao
WHERE data_retirada >= '2025-06-01'
AND data_retirada < '2025-07-01';

-- Restaura a visibilidade (NAO recria o indice; ele continuava existindo)
ALTER TABLE locacao
ALTER INDEX idx_loc_data VISIBLE;

-- Confirma a restauracao (IS_VISIBLE = YES)
SELECT INDEX_NAME, IS_VISIBLE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'lab_otimizacao' AND TABLE_NAME = 'locacao'
GROUP BY INDEX_NAME, IS_VISIBLE;


-- =====================================================================
-- PARTE 5 - FECHAMENTO (respostas no documento de resolucao)
-- Opcional: tamanho dos indices e custo de escrita
-- =====================================================================
SELECT TABLE_NAME, ROUND(DATA_LENGTH/1024/1024,1) AS dados_mb,
       ROUND(INDEX_LENGTH/1024/1024,1) AS indices_mb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'lab_otimizacao';
