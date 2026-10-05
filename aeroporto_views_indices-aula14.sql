-- =====================================================================
-- Aula prática: Views e Índices - Projeto Aeroporto (MySQL 8+)
-- Schema de EXEMPLO. Se o seu banco é diferente, adapte os nomes.
-- =====================================================================
DROP DATABASE IF EXISTS aeroporto_aula;
CREATE DATABASE aeroporto_aula;
USE aeroporto_aula;

CREATE TABLE aeroportos (id INT PRIMARY KEY, sigla CHAR(3), cidade VARCHAR(60));
CREATE TABLE companhias (id INT PRIMARY KEY, nome VARCHAR(60));
CREATE TABLE voos (
  id INT PRIMARY KEY, numero VARCHAR(10), companhia_id INT,
  origem_id INT, destino_id INT, data_partida DATE,
  status VARCHAR(15), capacidade INT,
  FOREIGN KEY (companhia_id) REFERENCES companhias(id),
  FOREIGN KEY (origem_id)  REFERENCES aeroportos(id),
  FOREIGN KEY (destino_id) REFERENCES aeroportos(id)
);
CREATE TABLE passageiros (id INT PRIMARY KEY, nome VARCHAR(80));
CREATE TABLE reservas (
  id INT PRIMARY KEY, voo_id INT, passageiro_id INT, status VARCHAR(15),
  FOREIGN KEY (voo_id) REFERENCES voos(id),
  FOREIGN KEY (passageiro_id) REFERENCES passageiros(id)
);

-- ---------- Dados de teste (200 mil voos, para o índice fazer diferença)
SET SESSION cte_max_recursion_depth = 250000;
INSERT INTO aeroportos SELECT n, CONCAT('A', LPAD(n,2,'0')), CONCAT('Cidade',n)
  FROM (WITH RECURSIVE s AS (SELECT 1 n UNION ALL SELECT n+1 FROM s WHERE n<20) SELECT n FROM s) t;
INSERT INTO companhias SELECT n, CONCAT('Cia',n)
  FROM (WITH RECURSIVE s AS (SELECT 1 n UNION ALL SELECT n+1 FROM s WHERE n<5) SELECT n FROM s) t;
INSERT INTO voos
SELECT n, CONCAT('V',n), 1+FLOOR(RAND()*5), 1+FLOOR(RAND()*20), 1+FLOOR(RAND()*20),
       DATE_ADD('2026-01-01', INTERVAL FLOOR(RAND()*360) DAY),
       CASE WHEN r<0.60 THEN 'agendado' WHEN r<0.95 THEN 'concluido'
            WHEN r<0.97 THEN 'atrasado' ELSE 'cancelado' END, 180
FROM (WITH RECURSIVE s AS (SELECT 1 n UNION ALL SELECT n+1 FROM s WHERE n<200000)
      SELECT n, RAND() r FROM s) t;
INSERT INTO passageiros SELECT n, CONCAT('Passageiro',n)
  FROM (WITH RECURSIVE s AS (SELECT 1 n UNION ALL SELECT n+1 FROM s WHERE n<5000) SELECT n FROM s) t;
INSERT INTO reservas SELECT n, 1+FLOOR(RAND()*2000), 1+FLOOR(RAND()*5000),
       IF(RAND()<0.8,'confirmada','cancelada')
  FROM (WITH RECURSIVE s AS (SELECT 1 n UNION ALL SELECT n+1 FROM s WHERE n<30000) SELECT n FROM s) t;

-- =====================================================================
-- ETAPA 2 - VIEWS
-- =====================================================================
-- View 1: JOIN (voos com nomes legíveis). Somente leitura (vários JOINs).
CREATE OR REPLACE VIEW vw_voos_detalhados AS
SELECT v.id, v.numero, cp.nome AS companhia, ao.sigla AS origem,
       ad.sigla AS destino, v.data_partida, v.status
FROM voos v
JOIN companhias cp ON cp.id = v.companhia_id
JOIN aeroportos ao ON ao.id = v.origem_id
JOIN aeroportos ad ON ad.id = v.destino_id;

-- View 2: AGREGAÇÃO (ocupação por voo). Não atualizável (GROUP BY/COUNT).
CREATE OR REPLACE VIEW vw_ocupacao_voo AS
SELECT v.id AS voo_id, v.numero, v.capacidade,
       COUNT(r.id) AS reservas_confirmadas,
       ROUND(100 * COUNT(r.id) / v.capacidade, 1) AS pct_ocupacao
FROM voos v
LEFT JOIN reservas r ON r.voo_id = v.id AND r.status = 'confirmada'
GROUP BY v.id, v.numero, v.capacidade;

-- View 3: SIMPLES e ATUALIZÁVEL, com WITH CHECK OPTION.
CREATE OR REPLACE VIEW vw_voos_ativos AS
SELECT id, numero, data_partida, status, capacidade
FROM voos
WHERE status IN ('agendado','atrasado')
WITH CHECK OPTION;

-- Testes rápidos
SELECT * FROM vw_voos_detalhados LIMIT 5;
SELECT * FROM vw_ocupacao_voo WHERE reservas_confirmadas > 0 LIMIT 5;
UPDATE vw_voos_ativos SET status='atrasado' WHERE id=1;      -- OK
-- UPDATE vw_voos_ativos SET status='concluido' WHERE id=1;  -- ERRO: CHECK OPTION

-- =====================================================================
-- ETAPA 3 - ÍNDICE (medir ANTES, criar, medir DEPOIS)
-- =====================================================================
SHOW VARIABLES LIKE 'performance_schema';            -- deve ser ON

-- ANTES
EXPLAIN SELECT * FROM voos WHERE status = 'atrasado';   -- anote type e rows
TRUNCATE TABLE performance_schema.events_statements_summary_by_digest;
SELECT * FROM voos WHERE status = 'atrasado';
SELECT * FROM voos WHERE status = 'atrasado';
SELECT * FROM voos WHERE status = 'atrasado';
SELECT DIGEST_TEXT, COUNT_STAR AS execucoes,
       AVG_TIMER_WAIT/1000000000 AS tempo_medio_ms,
       SUM_ROWS_EXAMINED AS linhas_examinadas_total
FROM performance_schema.events_statements_summary_by_digest
WHERE DIGEST_TEXT LIKE '%voos%' AND DIGEST_TEXT LIKE '%`status` = ?%'
ORDER BY AVG_TIMER_WAIT DESC;

-- CRIAR
CREATE INDEX idx_voos_status ON voos(status);

-- DEPOIS (mesmos passos, com TRUNCATE antes)
EXPLAIN SELECT * FROM voos WHERE status = 'atrasado';
TRUNCATE TABLE performance_schema.events_statements_summary_by_digest;
SELECT * FROM voos WHERE status = 'atrasado';
SELECT * FROM voos WHERE status = 'atrasado';
SELECT * FROM voos WHERE status = 'atrasado';
SELECT DIGEST_TEXT, COUNT_STAR AS execucoes,
       AVG_TIMER_WAIT/1000000000 AS tempo_medio_ms,
       SUM_ROWS_EXAMINED AS linhas_examinadas_total
FROM performance_schema.events_statements_summary_by_digest
WHERE DIGEST_TEXT LIKE '%voos%' AND DIGEST_TEXT LIKE '%`status` = ?%'
ORDER BY AVG_TIMER_WAIT DESC;

-- O índice está sendo usado de fato?
SELECT OBJECT_NAME AS tabela, INDEX_NAME AS indice,
       COUNT_READ AS leituras, COUNT_FETCH AS buscas
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'aeroporto_aula' AND OBJECT_NAME = 'voos'
ORDER BY COUNT_READ DESC;

-- EXTRA: coluna de baixa seletividade (60% das linhas): índice tende a não ajudar
EXPLAIN SELECT * FROM voos WHERE status = 'agendado';
