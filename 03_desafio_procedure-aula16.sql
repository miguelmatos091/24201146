-- ============================================================
-- DESAFIO (Seção 21 do material)
-- Procedimento de reserva de assento com proteção completa
-- contra concorrência
--
-- PRÉ-REQUISITOS: rodar antes, nesta ordem:
--   01_modelagem_estrutura.sql
-- Requer PostgreSQL 11+ (procedures com COMMIT/ROLLBACK).
--
-- Checklist dos 12 requisitos do desafio, mapeados no código:
--   1,2,3  -> parâmetros de entrada da procedure
--   4      -> verificação de existência do assento
--   5      -> verificação de disponibilidade
--   6      -> uso de transação (implícita na PROCEDURE + CALL)
--   7      -> SELECT ... FOR UPDATE (proteção contra concorrência)
--   8      -> UPDATE condicional do status
--   9      -> INSERT da reserva
--   10     -> COMMIT só quando todas as etapas foram concluídas
--   11     -> ROLLBACK quando há erro
--   12     -> índice único parcial (criado no script 01) +
--              tratamento de unique_violation
-- ============================================================


-- ============================================================
-- PARTE 1 — Tabela de log
-- Requisito adicional: "Registrar o resultado de cada transação"
-- ============================================================
CREATE TABLE IF NOT EXISTS log_tentativas_reserva (
    id BIGSERIAL PRIMARY KEY,
    passageiro_id BIGINT,
    voo_id BIGINT,
    numero_assento VARCHAR(10),
    resultado VARCHAR(10),
    mensagem VARCHAR(300),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- PARTE 2 — Procedure principal: reservar_assento
-- Entrega central do desafio (requisitos 1 a 12)
-- ============================================================
CREATE OR REPLACE PROCEDURE reservar_assento(
    IN  p_passageiro_id  BIGINT,          -- 1) ID do passageiro
    IN  p_voo_id         BIGINT,          -- 2) ID do voo
    IN  p_numero_assento VARCHAR,         -- 3) número do assento
    INOUT p_resultado    VARCHAR DEFAULT NULL,  -- 'SUCESSO' ou 'ERRO'
    INOUT p_mensagem     VARCHAR DEFAULT NULL   -- detalhe do resultado
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_assento_id   BIGINT;
    v_status_atual VARCHAR;
    v_linhas       INTEGER;
    v_falhou       BOOLEAN := FALSE;
BEGIN
    -- 4) Verifica se o assento existe
    -- 7) FOR UPDATE bloqueia a linha, protegendo contra outra
    --    transação concorrente que tente ler/alterar o mesmo assento
    SELECT id, status
      INTO v_assento_id, v_status_atual
    FROM assentos
    WHERE voo_id = p_voo_id
      AND numero = p_numero_assento
    FOR UPDATE;

    IF NOT FOUND THEN
        p_resultado := 'ERRO';
        p_mensagem  := format('Assento %s não existe no voo %s.',
                              p_numero_assento, p_voo_id);
        v_falhou := TRUE;
    END IF;

    -- 5) Verifica disponibilidade (só prossegue se ainda não falhou)
    IF NOT v_falhou AND v_status_atual <> 'DISPONIVEL' THEN
        p_resultado := 'ERRO';
        p_mensagem  := format('Assento %s não está disponível (status atual: %s).',
                              p_numero_assento, v_status_atual);
        v_falhou := TRUE;
    END IF;

    -- 8) Atualização condicional do status.
    --    Mesmo já tendo o lock via FOR UPDATE, mantemos a condição
    --    "AND status = 'DISPONIVEL'" como segunda camada de defesa
    --    (seção 12 do material: reduz a janela entre verificação e
    --    atualização e protege contra qualquer descuido de lock).
    IF NOT v_falhou THEN
        UPDATE assentos
           SET status = 'RESERVADO'
         WHERE id = v_assento_id
           AND status = 'DISPONIVEL';

        GET DIAGNOSTICS v_linhas = ROW_COUNT;

        IF v_linhas = 0 THEN
            p_resultado := 'ERRO';
            p_mensagem  := 'Assento foi alterado por outra transação concorrente entre a verificação e a atualização.';
            v_falhou := TRUE;
        END IF;
    END IF;

    -- 9) Insere a reserva.
    -- 12) O bloco interno captura unique_violation, que é disparada
    --     pelo índice único parcial uq_reserva_assento_ativa caso já
    --     exista uma reserva CONFIRMADA para este assento — a última
    --     linha de defesa, mesmo que toda a lógica acima falhe.
    IF NOT v_falhou THEN
        BEGIN
            INSERT INTO reservas (passageiro_id, assento_id)
            VALUES (p_passageiro_id, v_assento_id);
        EXCEPTION
            WHEN unique_violation THEN
                p_resultado := 'ERRO';
                p_mensagem  := 'Já existe uma reserva confirmada ativa para este assento.';
                v_falhou := TRUE;
            WHEN foreign_key_violation THEN
                p_resultado := 'ERRO';
                p_mensagem  := format('Passageiro %s não existe.', p_passageiro_id);
                v_falhou := TRUE;
        END;
    END IF;

    -- 10) e 11) Confirma ou desfaz a transação.
    -- Este COMMIT/ROLLBACK fica FORA de qualquer bloco com EXCEPTION
    -- anexada, requisito do PostgreSQL para permitir controle de
    -- transação dentro de uma PROCEDURE.
    IF v_falhou THEN
        ROLLBACK;
    ELSE
        p_resultado := 'SUCESSO';
        p_mensagem  := format('Assento %s reservado com sucesso para o passageiro %s.',
                              p_numero_assento, p_passageiro_id);
        COMMIT;
    END IF;

    -- Observação: qualquer erro verdadeiramente inesperado, não
    -- tratado nos blocos acima (ex.: falha de conexão, erro de
    -- sistema), propaga para fora da procedure. Nesse caso o
    -- PostgreSQL desfaz automaticamente a transação do CALL,
    -- cumprindo o requisito 11 mesmo sem um WHEN OTHERS explícito
    -- neste nível (que aqui não pode existir, pois impediria o
    -- COMMIT/ROLLBACK acima).
END;
$$;


-- ============================================================
-- PARTE 3 — Wrapper de teste com registro em log
-- ============================================================
CREATE OR REPLACE PROCEDURE testar_reserva(
    IN p_passageiro_id  BIGINT,
    IN p_voo_id         BIGINT,
    IN p_numero_assento VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_resultado VARCHAR;
    v_mensagem  VARCHAR;
BEGIN
    CALL reservar_assento(p_passageiro_id, p_voo_id, p_numero_assento,
                           v_resultado, v_mensagem);

    INSERT INTO log_tentativas_reserva
        (passageiro_id, voo_id, numero_assento, resultado, mensagem)
    VALUES
        (p_passageiro_id, p_voo_id, p_numero_assento, v_resultado, v_mensagem);

    COMMIT;

    RAISE NOTICE '[%] Passageiro % / Assento % -> %',
        v_resultado, p_passageiro_id, p_numero_assento, v_mensagem;
END;
$$;


-- ============================================================
-- PARTE 4 — Procedures auxiliares para simular deadlock
-- (requisito adicional: "Simular um deadlock")
--
-- A procedure reservar_assento, sozinha, bloqueia UM único
-- assento por chamada e faz commit ao final — por isso, usada
-- normalmente, ela é DEADLOCK-SAFE por construção (boa prática
-- da seção 22: "bloquear somente os registros necessários").
-- Para demonstrar deadlock de fato, é preciso um cenário onde
-- uma mesma transação bloqueia MAIS DE UM assento, o que criamos
-- abaixo em duas versões: uma ingênua (com risco) e uma corrigida.
-- ============================================================

-- Versão INGÊNUA: bloqueia os assentos na ordem em que o
-- chamador informou, sem reordenar. Risco de deadlock se duas
-- sessões chamarem com listas em ordem invertida.
CREATE OR REPLACE PROCEDURE reservar_multiplos_assentos_sem_ordem(
    IN p_voo_id          BIGINT,
    IN p_numeros_assento VARCHAR[],
    INOUT p_resultado    VARCHAR DEFAULT NULL,
    INOUT p_mensagem     VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_numero VARCHAR;
    v_id     BIGINT;
BEGIN
    FOREACH v_numero IN ARRAY p_numeros_assento
    LOOP
        SELECT id INTO v_id
        FROM assentos
        WHERE voo_id = p_voo_id AND numero = v_numero
        FOR UPDATE;
    END LOOP;

    p_resultado := 'SUCESSO';
    p_mensagem  := 'Assentos bloqueados na ordem informada.';
    COMMIT;
END;
$$;

-- Versão CORRIGIDA: sempre bloqueia em ordem crescente de ID,
-- independentemente da ordem recebida. Elimina a espera circular
-- (seção 14/15 do material — "estabelecer uma ordem fixa para
-- adquirir bloqueios").
CREATE OR REPLACE PROCEDURE reservar_multiplos_assentos_seguro(
    IN p_voo_id          BIGINT,
    IN p_numeros_assento VARCHAR[],
    INOUT p_resultado    VARCHAR DEFAULT NULL,
    INOUT p_mensagem     VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    FOR v_id IN
        SELECT id FROM assentos
        WHERE voo_id = p_voo_id AND numero = ANY(p_numeros_assento)
        ORDER BY id  -- ordem fixa e consistente entre chamadas
    LOOP
        PERFORM 1 FROM assentos WHERE id = v_id FOR UPDATE;
    END LOOP;

    p_resultado := 'SUCESSO';
    p_mensagem  := 'Assentos bloqueados em ordem consistente (id crescente).';
    COMMIT;
END;
$$;


-- ============================================================
-- PARTE 5 — BATERIA DE TESTES
-- ============================================================

-- Reset do ambiente antes de começar
DELETE FROM reservas;
UPDATE assentos SET status = 'DISPONIVEL' WHERE voo_id = 1;


-- ------------------------------------------------------------
-- TESTE 1 — Dois passageiros tentando reservar o MESMO assento
-- (fluxo sequencial, mesma sessão: demonstra a REGRA DE NEGÓCIO)
-- ------------------------------------------------------------
CALL testar_reserva(1, 1, '10A');  -- Passageiro A -> esperado SUCESSO
CALL testar_reserva(2, 1, '10A');  -- Passageiro B -> esperado ERRO (já reservado)

-- Para testar a CONCORRÊNCIA REAL (as duas tentativas disputando
-- o mesmo instante), use duas sessões chamando a procedure ao
-- mesmo tempo, no padrão já demonstrado no Experimento B
-- (02_experimentos_A_B_C.sql). A procedure reservar_assento já
-- incorpora o SELECT...FOR UPDATE, então o comportamento será:
-- SESSAO 1: CALL reservar_assento(1, 1, '10B', NULL, NULL);
-- SESSAO 2: CALL reservar_assento(2, 1, '10B', NULL, NULL);
--   (execute nas duas sessões quase simultaneamente)
-- Resultado esperado: uma das sessões recebe SUCESSO, a outra
-- recebe ERRO com a mensagem de "não está disponível" ou de
-- "alterado por outra transação concorrente".


-- ------------------------------------------------------------
-- TESTE 2 — Dois passageiros reservando assentos DIFERENTES
-- ------------------------------------------------------------
CALL testar_reserva(1, 1, '10B');  -- esperado SUCESSO
CALL testar_reserva(2, 1, '10C');  -- esperado SUCESSO (assento diferente)


-- ------------------------------------------------------------
-- TESTE 3 — Simulação de deadlock
-- Requer DUAS SESSÕES reais. Antes de rodar, garanta que os
-- assentos 10A/10B/10C estejam livres novamente:
--   DELETE FROM reservas;
--   UPDATE assentos SET status = 'DISPONIVEL' WHERE voo_id = 1;
--
-- 3.1) VERSÃO COM RISCO (reservar_multiplos_assentos_sem_ordem)
--
-- ----------------- SESSAO 1 -----------------
CALL reservar_multiplos_assentos_sem_ordem(
    1, ARRAY['10A', '10B'], NULL, NULL
);
-- Antes de rodar isso de fato, para provocar o deadlock você
-- precisa interromper a procedure NO MEIO — o que uma CALL única
-- não permite (ela roda até o fim de uma vez). Por isso, para
-- observar o deadlock de fato, execute o equivalente manual em
-- duas sessões (mesma lógica da procedure, mas passo a passo,
-- como no Experimento C):
--
-- SESSAO 1:
BEGIN;
SELECT id FROM assentos WHERE voo_id = 1 AND numero = '10A' FOR UPDATE;
-- aguarda antes do próximo passo
SELECT id FROM assentos WHERE voo_id = 1 AND numero = '10B' FOR UPDATE;
COMMIT;

-- SESSAO 2 (executar o primeiro SELECT logo após o primeiro da Sessão 1):
BEGIN;
SELECT id FROM assentos WHERE voo_id = 1 AND numero = '10B' FOR UPDATE;
-- aguarda antes do próximo passo
SELECT id FROM assentos WHERE voo_id = 1 AND numero = '10A' FOR UPDATE;
COMMIT;
-- Resultado esperado: uma das duas sessões recebe
-- "ERROR: deadlock detected" (ver Experimento C para o passo a
-- passo completo e o roteiro de qual comando roda em qual ordem).

-- 3.2) VERSÃO SEGURA (reservar_multiplos_assentos_seguro)
-- Repetindo o mesmo teste com a versão que ordena os locks por ID:
-- SESSAO 1:
CALL reservar_multiplos_assentos_seguro(1, ARRAY['10A', '10B'], NULL, NULL);
-- SESSAO 2 (chamando com a ordem invertida no array):
CALL reservar_multiplos_assentos_seguro(1, ARRAY['10B', '10A'], NULL, NULL);
-- Como a procedure reordena por ID internamente antes de bloquear,
-- as duas sessões sempre tentam adquirir os locks na mesma ordem
-- (10A antes de 10B, por exemplo), então uma delas apenas espera
-- a outra terminar — sem deadlock, só espera sequencial.


-- ------------------------------------------------------------
-- VERIFICAÇÃO E REGISTRO FINAL
-- ------------------------------------------------------------
SELECT * FROM log_tentativas_reserva ORDER BY criado_em;

SELECT r.id, p.nome AS passageiro, a.numero AS assento, r.status
FROM reservas r
JOIN passageiros p ON p.id = r.passageiro_id
JOIN assentos a ON a.id = r.assento_id
ORDER BY r.id;


-- ============================================================
-- PARTE 6 — Explicação da estratégia de concorrência utilizada
-- (requisito adicional do desafio)
-- ============================================================
-- Estratégia: LOCKING PESSIMISTA em múltiplas camadas.
--
-- 1) SELECT ... FOR UPDATE (dentro de reservar_assento) bloqueia
--    a linha do assento assim que ela é lida, impedindo que outra
--    transação concorrente leia/altere o mesmo registro até que
--    a transação atual termine (COMMIT ou ROLLBACK). Isso resolve
--    a condição de corrida descrita na seção 7 do material.
--
-- 2) UPDATE condicional ("WHERE status = 'DISPONIVEL'") como
--    segunda camada: mesmo que o lock já garanta exclusividade,
--    a condição extra deixa claro, via ROW_COUNT, se a operação
--    de fato mudou algo — evitando decisões baseadas apenas na
--    leitura anterior (seção 12 do material).
--
-- 3) Índice único parcial (uq_reserva_assento_ativa, criado no
--    script 01) como REDE DE SEGURANÇA em nível de banco: mesmo
--    que a aplicação (ou um bug na procedure) falhe em qualquer
--    das camadas acima, o próprio SGBD rejeita duas reservas
--    CONFIRMADAS para o mesmo assento (seção 13 do material).
--
-- 4) Transação curta: cada chamada de reservar_assento faz o
--    mínimo possível dentro da transação (verificar, bloquear,
--    atualizar, inserir, commitar) e não interage com o usuário
--    no meio do caminho — reduzindo o tempo em que o lock fica
--    ativo (boa prática da seção 22).
--
-- 5) Prevenção de deadlock por ORDEM CONSISTENTE de aquisição de
--    locks: a procedure principal só bloqueia um recurso por vez,
--    o que a torna deadlock-safe por construção. Para o caso de
--    múltiplos assentos (reservar_multiplos_assentos_seguro),
--    a prevenção é feita ordenando os locks por ID antes de
--    adquiri-los, conforme a técnica da seção 15 do material.
--
-- Em resumo: o desenho combina bloqueio explícito (locking),
-- validação condicional, restrição de integridade (MVCC + unique
-- index) e boas práticas de transação curta — não dependendo de
-- uma única camada para garantir que dois passageiros nunca
-- fiquem com reserva confirmada para o mesmo assento.
