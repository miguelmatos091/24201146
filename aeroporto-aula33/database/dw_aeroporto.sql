-- =====================================================================
-- Painéis do Aeroporto: modelo estrela (DW), ETL e consultas dos painéis
-- Rode como ADMINISTRADOR:  mysql -u root -p < database/dw_aeroporto.sql
-- O DW fica em um banco separado (dw_aeroporto) e lê o OLTP (aeroporto.voos).
--
-- Origem: aeroporto.voos (colunas atuais: aeroporto_destino, portao, horario, status, deleted_at).
-- O OLTP atual não tem data do voo, companhia nem passageiros (ver
-- ENTREGA_PAINEIS.md, "Lacunas"). Por isso dim_tempo e dim_companhia só têm o
-- membro "Não informado" (-1) e as medidas de passageiros ficam NULL. Os painéis
-- 1, 3 e 5 já funcionam; os painéis 2 e 4 mostram a lacuna (sem linhas / só "Não informado").
-- =====================================================================
CREATE DATABASE IF NOT EXISTS dw_aeroporto CHARACTER SET utf8mb4;
USE dw_aeroporto;

-- ---------------------------------------------------------------------
-- 1) ESQUEMA ESTRELA
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS fato_voo;
DROP TABLE IF EXISTS dim_tempo;
DROP TABLE IF EXISTS dim_hora;
DROP TABLE IF EXISTS dim_destino;
DROP TABLE IF EXISTS dim_companhia;
DROP TABLE IF EXISTS dim_portao;
DROP TABLE IF EXISTS dim_status;

-- sk_tempo = AAAAMMDD (ex.: 20261123); -1 = "Sem data"
CREATE TABLE dim_tempo (
  sk_tempo      INT PRIMARY KEY,
  data          DATE NULL,
  ano           SMALLINT NULL,
  trimestre     TINYINT NULL,
  mes           TINYINT NULL,
  nome_mes      VARCHAR(15) NULL,
  ano_mes       VARCHAR(10) NULL,    -- '2026-11': permite ver o painel por mês
  dia           TINYINT NULL,
  dia_semana    VARCHAR(15) NULL,
  fim_de_semana BOOLEAN NULL
);

CREATE TABLE dim_hora (
  sk_hora      TINYINT PRIMARY KEY,  -- 0..23
  hora         TINYINT NOT NULL,
  faixa_do_dia VARCHAR(15) NOT NULL  -- Madrugada, Manhã, Tarde, Noite
);

CREATE TABLE dim_destino (
  sk_destino INT AUTO_INCREMENT PRIMARY KEY,
  destino    VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_companhia (
  sk_companhia INT AUTO_INCREMENT PRIMARY KEY,
  companhia    VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE dim_portao (
  sk_portao INT AUTO_INCREMENT PRIMARY KEY,
  portao    VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE dim_status (
  sk_status INT AUTO_INCREMENT PRIMARY KEY,
  status    VARCHAR(20) NOT NULL UNIQUE
);

-- GRÃO: uma linha = um voo (ativo) do OLTP.
CREATE TABLE fato_voo (
  id_voo_origem       INT NOT NULL PRIMARY KEY, -- dimensão degenerada: id em aeroporto.voos
  numero_voo          INT NOT NULL,             -- dimensão degenerada
  sk_tempo            INT NOT NULL,
  sk_hora             TINYINT NOT NULL,
  sk_destino          INT NOT NULL,
  sk_companhia        INT NOT NULL,
  sk_portao           INT NOT NULL,
  sk_status           INT NOT NULL,
  qtd_voos            TINYINT NOT NULL DEFAULT 1, -- aditiva (sempre 1 neste grão)
  qtd_passageiros     INT NULL,                   -- aditiva (lacuna: sem passageiros no OLTP)
  capacidade_assentos INT NULL,                   -- aditiva (lacuna)
  atraso_min          INT NULL,                   -- aditiva; a média é soma/qtd_voos (lacuna)
  FOREIGN KEY (sk_tempo)     REFERENCES dim_tempo(sk_tempo),
  FOREIGN KEY (sk_hora)      REFERENCES dim_hora(sk_hora),
  FOREIGN KEY (sk_destino)   REFERENCES dim_destino(sk_destino),
  FOREIGN KEY (sk_companhia) REFERENCES dim_companhia(sk_companhia),
  FOREIGN KEY (sk_portao)    REFERENCES dim_portao(sk_portao),
  FOREIGN KEY (sk_status)    REFERENCES dim_status(sk_status)
);

-- ---------------------------------------------------------------------
-- 2) ETL (dimensões ANTES da fato). Pode ser rodado de novo: recarga completa.
-- ---------------------------------------------------------------------

-- EXTRACT/TRANSFORM/LOAD das dimensões
-- Membros "Não informado" (-1) para dados que o OLTP não tem ou que vêm nulos.
INSERT IGNORE INTO dim_tempo (sk_tempo, nome_mes, ano_mes) VALUES (-1, 'Sem data', 'Sem data');
INSERT IGNORE INTO dim_destino   (sk_destino, destino)     VALUES (-1, 'Não informado');
INSERT IGNORE INTO dim_companhia (sk_companhia, companhia) VALUES (-1, 'Não informado');
INSERT IGNORE INTO dim_portao    (sk_portao, portao)       VALUES (-1, 'Sem portão');
INSERT IGNORE INTO dim_status    (sk_status, status)       VALUES (-1, 'Não informado');

INSERT IGNORE INTO dim_hora (sk_hora, hora, faixa_do_dia)
SELECT n, n,
       CASE WHEN n < 6  THEN 'Madrugada'
            WHEN n < 12 THEN 'Manhã'
            WHEN n < 18 THEN 'Tarde'
            ELSE 'Noite' END
FROM (WITH RECURSIVE h AS (SELECT 0 AS n UNION ALL SELECT n + 1 FROM h WHERE n < 23)
      SELECT n FROM h) t;

-- Atenção: este ETL usa `aeroporto_destino`, o estado atual do projeto (migrations
-- 003/004 da Aula 30: `destino` foi removida). Se o seu banco de origem ainda tem a
-- coluna antiga `destino` (antes da 003), troque `aeroporto_destino` por `destino`
-- nas duas consultas que a usam (dim_destino e fato_voo).
INSERT IGNORE INTO dim_destino (destino)
SELECT DISTINCT TRIM(aeroporto_destino) FROM aeroporto.voos
WHERE deleted_at IS NULL AND aeroporto_destino IS NOT NULL AND TRIM(aeroporto_destino) <> '';

INSERT IGNORE INTO dim_portao (portao)
SELECT DISTINCT TRIM(portao) FROM aeroporto.voos
WHERE deleted_at IS NULL AND portao IS NOT NULL AND TRIM(portao) <> '';

INSERT IGNORE INTO dim_status (status)
SELECT DISTINCT status FROM aeroporto.voos WHERE deleted_at IS NULL;

-- Quando o OLTP tiver data do voo, carregue o calendário (exemplo, 2026-2027):
-- INSERT IGNORE INTO dim_tempo
-- SELECT DATE_FORMAT(d, '%Y%m%d') + 0, d, YEAR(d), QUARTER(d), MONTH(d),
--        MONTHNAME(d), DATE_FORMAT(d, '%Y-%m'), DAY(d), DAYNAME(d), DAYOFWEEK(d) IN (1, 7)
-- FROM (WITH RECURSIVE c AS (SELECT DATE('2026-01-01') AS d
--                            UNION ALL SELECT d + INTERVAL 1 DAY FROM c WHERE d < '2027-12-31')
--       SELECT d FROM c) t;  -- (aumente cte_max_recursion_depth se necessário)

-- LOAD da fato (recarga completa; exclui voos apagados pelo soft delete)
DELETE FROM fato_voo;

INSERT INTO fato_voo
  (id_voo_origem, numero_voo, sk_tempo, sk_hora, sk_destino, sk_companhia,
   sk_portao, sk_status, qtd_voos, qtd_passageiros, capacidade_assentos, atraso_min)
SELECT v.id, v.numero_voo,
       -1,                              -- sem data no OLTP
       HOUR(v.horario),
       COALESCE(dd.sk_destino, -1),     -- destino nulo/vazio vira "Não informado"
       -1,                              -- sem companhia no OLTP
       COALESCE(dp.sk_portao, -1),
       ds.sk_status,
       1, NULL, NULL, NULL
FROM aeroporto.voos v
LEFT JOIN dim_destino dd ON dd.destino = TRIM(v.aeroporto_destino)
LEFT JOIN dim_portao dp  ON dp.portao  = TRIM(v.portao)
JOIN dim_status ds       ON ds.status  = v.status
WHERE v.deleted_at IS NULL;

-- Quando existirem reservas no OLTP, NÃO junte `reservas` direto ao voo (cada
-- reserva multiplicaria a linha do voo e inflaria qtd_voos). Agregue antes:
--   LEFT JOIN (SELECT voo_id, COUNT(*) AS pax FROM aeroporto.reservas
--              WHERE status = 'confirmada' GROUP BY voo_id) r ON r.voo_id = v.id
--   ... COALESCE(r.pax, 0) AS qtd_passageiros

-- ---------------------------------------------------------------------
-- 3) CONSULTAS DOS PAINÉIS (partem sempre da fato)
-- ---------------------------------------------------------------------

-- PAINEL 1: destinos mais frequentes (ranking)
SELECT d.destino, SUM(f.qtd_voos) AS voos
FROM   fato_voo f
JOIN   dim_destino d ON d.sk_destino = f.sk_destino
WHERE  d.sk_destino <> -1
GROUP  BY d.sk_destino, d.destino
ORDER  BY voos DESC, d.destino
LIMIT  10;

-- PAINEL 2: passageiros por mês (evolução). Hoje retorna 0 linhas: lacuna (sem data e sem passageiros).
SELECT t.ano_mes, SUM(f.qtd_passageiros) AS passageiros
FROM   fato_voo f
JOIN   dim_tempo t ON t.sk_tempo = f.sk_tempo
WHERE  t.sk_tempo <> -1
GROUP  BY t.ano, t.mes, t.ano_mes
ORDER  BY t.ano, t.mes;

-- PAINEL 3: número de voos (indicador + quebra por status)
SELECT SUM(f.qtd_voos) AS total_voos FROM fato_voo f;

SELECT s.status, SUM(f.qtd_voos) AS voos
FROM   fato_voo f
JOIN   dim_status s ON s.sk_status = f.sk_status
GROUP  BY s.sk_status, s.status
ORDER  BY voos DESC;

-- PAINEL 4: companhia mais atuante (ranking + participação).
-- Hoje retorna 0 linhas (só existe "Não informado"): lacuna.
SELECT c.companhia,
       SUM(f.qtd_voos) AS voos,
       ROUND(100 * SUM(f.qtd_voos) / SUM(SUM(f.qtd_voos)) OVER (), 1) AS pct_voos
FROM   fato_voo f
JOIN   dim_companhia c ON c.sk_companhia = f.sk_companhia
WHERE  c.sk_companhia <> -1
GROUP  BY c.sk_companhia, c.companhia
ORDER  BY voos DESC
LIMIT  5;

-- PAINEL 5 (livre): pico de operação por faixa do dia e hora
SELECT h.faixa_do_dia, h.hora, SUM(f.qtd_voos) AS voos
FROM   fato_voo f
JOIN   dim_hora h ON h.sk_hora = f.sk_hora
GROUP  BY h.faixa_do_dia, h.hora
ORDER  BY h.hora;
