-- ============================================================
-- SISTEMA DE RESERVAS DE ASSENTOS - AEROPORTO
-- Etapa: Modelagem conceitual + Criação da estrutura do banco
-- Referente aos Objetivos 1 e 2 da atividade:
--   1. Modelar entidades relacionadas a voos, aeronaves,
--      passageiros e reservas.
--   2. Identificar o problema de concorrência na reserva
--      de assentos.
-- Sintaxe: PostgreSQL
-- ============================================================

-- ------------------------------------------------------------
-- Ordem de criação: respeita as dependências de FK
-- aeronaves -> voos -> assentos -> reservas
-- passageiros -> reservas
-- ------------------------------------------------------------

-- 1) AERONAVES
-- Entidade independente. Representa a aeronave utilizada no voo.
CREATE TABLE aeronaves (
    id BIGSERIAL PRIMARY KEY,
    fabricante VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    quantidade_assentos INTEGER NOT NULL
        CHECK (quantidade_assentos > 0)
);

-- 2) VOOS
-- Depende de aeronaves. Representa um voo recebido pelo aeroporto.
-- Observação de modelagem: o campo "status" não teve seus valores
-- possíveis definidos no documento de referência, então não é
-- aplicado CHECK de domínio fechado aqui (evita travar a tabela
-- com valores que o professor não especificou).
CREATE TABLE voos (
    id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    origem VARCHAR(100) NOT NULL,
    destino VARCHAR(100) NOT NULL,
    data_hora_saida TIMESTAMP NOT NULL,
    aeronave_id BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PROGRAMADO',

    CONSTRAINT fk_voo_aeronave
        FOREIGN KEY (aeronave_id)
        REFERENCES aeronaves(id)
);

-- Índice de apoio para joins/filtros por aeronave
CREATE INDEX idx_voos_aeronave ON voos(aeronave_id);

-- 3) PASSAGEIROS
-- Entidade independente. Representa uma pessoa que pode reservar.
CREATE TABLE passageiros (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    documento VARCHAR(30) NOT NULL UNIQUE
);

-- 4) ASSENTOS
-- Depende de voos (e não de aeronaves diretamente): cada voo tem
-- seu próprio mapa de assentos com status independente, mesmo que
-- reutilize a mesma aeronave física em outro horário.
CREATE TABLE assentos (
    id BIGSERIAL PRIMARY KEY,
    voo_id BIGINT NOT NULL,
    numero VARCHAR(10) NOT NULL,
    classe VARCHAR(30) NOT NULL DEFAULT 'ECONOMICA'
        CHECK (classe IN ('ECONOMICA', 'EXECUTIVA', 'PRIMEIRA')),
    status VARCHAR(30) NOT NULL DEFAULT 'DISPONIVEL'
        CHECK (status IN ('DISPONIVEL', 'RESERVADO', 'BLOQUEADO')),

    CONSTRAINT fk_assento_voo
        FOREIGN KEY (voo_id)
        REFERENCES voos(id),

    CONSTRAINT uq_assento_voo
        UNIQUE (voo_id, numero)
);

CREATE INDEX idx_assentos_voo ON assentos(voo_id);

-- Acelera a consulta de disponibilidade (usada no cenário de
-- condição de corrida e nos experimentos com FOR UPDATE)
CREATE INDEX idx_assentos_voo_status ON assentos(voo_id, status);

-- 5) RESERVAS
-- Depende de passageiros e assentos. Representa a associação
-- entre um passageiro e um assento em um voo.
CREATE TABLE reservas (
    id BIGSERIAL PRIMARY KEY,
    passageiro_id BIGINT NOT NULL,
    assento_id BIGINT NOT NULL,
    data_reserva TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'CONFIRMADA'
        CHECK (status IN ('CONFIRMADA', 'CANCELADA')),

    CONSTRAINT fk_reserva_passageiro
        FOREIGN KEY (passageiro_id)
        REFERENCES passageiros(id),

    CONSTRAINT fk_reserva_assento
        FOREIGN KEY (assento_id)
        REFERENCES assentos(id)
);

CREATE INDEX idx_reservas_passageiro ON reservas(passageiro_id);

-- ------------------------------------------------------------
-- RESTRIÇÃO CRÍTICA DE CONCORRÊNCIA (Objetivo 2)
-- Regra de negócio: "para cada voo e assento, deve existir no
-- máximo uma reserva ATIVA".
--
-- Um UNIQUE comum em assento_id impediria reaproveitar o assento
-- após um cancelamento. Por isso o índice é parcial: só considera
-- linhas com status = 'CONFIRMADA'. Isso garante, no próprio banco
-- (e não só na aplicação), que dois passageiros nunca fiquem com
-- reserva confirmada para o mesmo assento simultaneamente -- mesmo
-- que a camada de aplicação falhe em validar isso.
-- ------------------------------------------------------------
CREATE UNIQUE INDEX uq_reserva_assento_ativa
ON reservas (assento_id)
WHERE status = 'CONFIRMADA';


-- ============================================================
-- DADOS DE TESTE
-- ============================================================

INSERT INTO aeronaves (fabricante, modelo, quantidade_assentos)
VALUES ('Airbus', 'A320', 180);

INSERT INTO voos (codigo, origem, destino, data_hora_saida, aeronave_id)
VALUES ('AB1234', 'Brasília', 'São Paulo', '2026-10-10 10:00:00', 1);

INSERT INTO passageiros (nome, documento)
VALUES
    ('Passageiro A', 'DOC001'),
    ('Passageiro B', 'DOC002');

INSERT INTO assentos (voo_id, numero, classe)
VALUES
    (1, '10A', 'ECONOMICA'),
    (1, '10B', 'ECONOMICA'),
    (1, '10C', 'ECONOMICA');


-- ============================================================
-- CONSULTA DE VERIFICAÇÃO
-- Resultado esperado: 3 assentos do voo 1, todos DISPONIVEL
-- ============================================================
SELECT
    id,
    voo_id,
    numero,
    status
FROM assentos
WHERE voo_id = 1
ORDER BY numero;
