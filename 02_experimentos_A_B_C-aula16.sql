-- ============================================================
-- EXPERIMENTOS A, B e C
-- Simulação de disputa por assentos: locking, deadlock e MVCC
--
-- PRÉ-REQUISITO: rodar antes o script
--   01_modelagem_estrutura.sql
-- (cria as tabelas e insere o voo AB1234 com os assentos
--  10A, 10B, 10C, todos DISPONIVEL)
--
-- COMO EXECUTAR:
-- Abra DUAS conexões/abas separadas com o banco (ex: dois
-- terminais com `psql`, ou duas abas no DBeaver/pgAdmin).
-- Cada bloco abaixo indica claramente "SESSAO 1" ou "SESSAO 2"
-- e a ORDEM em que os comandos devem ser digitados.
-- Não copie os dois blocos de uma vez na mesma sessão.
-- ============================================================


-- ============================================================
-- ANTES DE COMEÇAR: conferir estado inicial
-- Execute em qualquer sessão avulsa.
-- Resultado esperado: 10A, 10B, 10C todos DISPONIVEL
-- ============================================================
SELECT id, voo_id, numero, status
FROM assentos
WHERE voo_id = 1
ORDER BY numero;


-- ############################################################
-- EXPERIMENTO A — Condição de corrida (SEM FOR UPDATE)
-- Objetivo: demonstrar que validar disponibilidade sem bloqueio
-- não é suficiente para proteger a reserva.
-- ############################################################

-- ----------------- SESSAO 1 (Passageiro A) -----------------
-- Passo A1: abrir a transação e consultar disponibilidade
BEGIN;

SELECT id, status
FROM assentos
WHERE voo_id = 1
  AND numero = '10A'
  AND status = 'DISPONIVEL';
-- Deve retornar 1 linha (id=1, status=DISPONIVEL)
-- NÃO EXECUTE O COMMIT AINDA. Vá para a Sessão 2.


-- ----------------- SESSAO 2 (Passageiro B) -----------------
-- Passo B1: em uma segunda janela, abrir outra transação e
-- consultar o MESMO assento, enquanto a Sessão 1 está aberta.
BEGIN;

SELECT id, status
FROM assentos
WHERE voo_id = 1
  AND numero = '10A'
  AND status = 'DISPONIVEL';
-- Também retorna 1 linha (id=1, DISPONIVEL) --
-- ESTE É O PROBLEMA: as duas sessões leram o assento como livre,
-- sem qualquer bloqueio impedindo isso.


-- ----------------- SESSAO 1 -----------------
-- Passo A2: prossegue com a reserva
UPDATE assentos
SET status = 'RESERVADO'
WHERE id = 1;

INSERT INTO reservas (passageiro_id, assento_id)
VALUES (1, 1);

COMMIT;
-- Sessão 1 conclui normalmente.


-- ----------------- SESSAO 2 -----------------
-- Passo B2: sem saber que a Sessão 1 já reservou, tenta prosseguir
UPDATE assentos
SET status = 'RESERVADO'
WHERE id = 1;
-- Esse UPDATE ainda funciona (não há erro de sintaxe/lock aqui,
-- porque a Sessão 1 já fez COMMIT e liberou o registro).

INSERT INTO reservas (passageiro_id, assento_id)
VALUES (2, 1);
-- Se a UNIQUE INDEX parcial (uq_reserva_assento_ativa) estiver
-- ativa (criada no script 01), este INSERT FALHA com erro de
-- violação de unicidade — a rede de segurança do banco entra em
-- ação mesmo com a aplicação tendo "deixado passar" a duplicidade.

COMMIT;
-- (ou ROLLBACK, dependendo do que o professor quiser observar)


-- ----------------- VERIFICAÇÃO -----------------
-- Confirme quantas reservas CONFIRMADAS existem para o assento 1.
-- Esperado: 1 (a da Sessão 1). A tentativa da Sessão 2 deve ter
-- sido rejeitada pela constraint de unicidade.
SELECT * FROM reservas WHERE assento_id = 1;


-- ############################################################
-- RESET antes do próximo experimento
-- Execute em qualquer sessão avulsa para voltar o 10A a
-- DISPONIVEL e limpar reservas de teste.
-- ############################################################
DELETE FROM reservas WHERE assento_id = 1;
UPDATE assentos SET status = 'DISPONIVEL' WHERE id = 1;


-- ############################################################
-- EXPERIMENTO B — Reserva segura com FOR UPDATE
-- Objetivo: demonstrar como o locking evita a condição de corrida.
-- ############################################################

-- ----------------- SESSAO 1 (Passageiro A) -----------------
-- Passo A1: inicia transação e bloqueia a linha do assento 10A
BEGIN;

SELECT id, status
FROM assentos
WHERE voo_id = 1
  AND numero = '10A'
  AND status = 'DISPONIVEL'
FOR UPDATE;
-- A linha do assento 1 agora está BLOQUEADA para esta transação.
-- NÃO EXECUTE O COMMIT AINDA. Vá para a Sessão 2.


-- ----------------- SESSAO 2 (Passageiro B) -----------------
-- Passo B1: tenta bloquear a MESMA linha
BEGIN;

SELECT id, status
FROM assentos
WHERE voo_id = 1
  AND numero = '10A'
  AND status = 'DISPONIVEL'
FOR UPDATE;
-- Esta sessão FICA AGUARDANDO (a query não retorna ainda).
-- É esperado: a Sessão 2 está presa esperando o lock da Sessão 1.
-- Deixe esta janela travada e volte para a Sessão 1.


-- ----------------- SESSAO 1 -----------------
-- Passo A2: conclui a reserva e libera o lock
UPDATE assentos
SET status = 'RESERVADO'
WHERE id = 1
  AND status = 'DISPONIVEL';

INSERT INTO reservas (passageiro_id, assento_id)
VALUES (1, 1);

COMMIT;
-- Assim que o COMMIT roda, o lock é liberado e a Sessão 2
-- (que estava esperando) recebe o controle de volta.


-- ----------------- SESSAO 2 -----------------
-- Neste momento a query FOR UPDATE da Sessão 2 finalmente retorna.
-- IMPORTANTE: como o filtro incluía "status = 'DISPONIVEL'" e o
-- assento já foi RESERVADO pela Sessão 1, a query retorna
-- ZERO LINHAS. Isso é o comportamento correto: a Sessão 2 deve
-- reconhecer que o assento não está mais disponível.

-- Passo B2: tenta a atualização condicional mesmo assim, para
-- demonstrar que ela falha de forma segura
UPDATE assentos
SET status = 'RESERVADO'
WHERE id = 1
  AND status = 'DISPONIVEL';
-- 0 linhas afetadas -> confirma que não há mais nada disponível

-- Como nenhuma linha foi afetada, a Sessão 2 deve desistir:
ROLLBACK;


-- ----------------- VERIFICAÇÃO -----------------
SELECT * FROM reservas WHERE assento_id = 1;
-- Esperado: apenas 1 reserva, a do Passageiro A (id=1)


-- ############################################################
-- RESET antes do próximo experimento
-- ############################################################
DELETE FROM reservas WHERE assento_id = 1;
UPDATE assentos SET status = 'DISPONIVEL' WHERE id IN (1, 2);


-- ############################################################
-- EXPERIMENTO C — Deadlock
-- Objetivo: provocar deliberadamente um impasse circular entre
-- duas transações e observar a detecção automática pelo SGBD.
-- ############################################################

-- ----------------- SESSAO 1 -----------------
-- Passo A1: bloqueia o assento 10A (id=1)
BEGIN;

SELECT *
FROM assentos
WHERE id = 1
FOR UPDATE;
-- Sessão 1 agora segura o lock do assento 1.
-- NÃO PROSSIGA AINDA. Vá para a Sessão 2.


-- ----------------- SESSAO 2 -----------------
-- Passo B1: bloqueia o assento 10B (id=2)
BEGIN;

SELECT *
FROM assentos
WHERE id = 2
FOR UPDATE;
-- Sessão 2 agora segura o lock do assento 2.
-- Volte para a Sessão 1.


-- ----------------- SESSAO 1 -----------------
-- Passo A2: tenta bloquear o assento 10B, que a Sessão 2 já detém
SELECT *
FROM assentos
WHERE id = 2
FOR UPDATE;
-- Esta sessão FICA AGUARDANDO o lock que a Sessão 2 possui.
-- Vá para a Sessão 2 SEM esperar aqui.


-- ----------------- SESSAO 2 -----------------
-- Passo B2: tenta bloquear o assento 10A, que a Sessão 1 já detém
SELECT *
FROM assentos
WHERE id = 1
FOR UPDATE;
-- ESPERA CIRCULAR CONFIGURADA:
--   Sessão 1 espera o assento 2 (preso pela Sessão 2)
--   Sessão 2 espera o assento 1 (preso pela Sessão 1)
--
-- O PostgreSQL detecta o ciclo automaticamente (checagem
-- periódica de deadlock) e cancela UMA das duas transações
-- com o erro:
--   ERROR: deadlock detected
--   DETAIL: Process ... waits for ShareLock on transaction ...
--
-- A sessão cancelada recebe o erro; a outra sessão finalmente
-- consegue seguir em frente com seu SELECT ... FOR UPDATE.


-- ----------------- Na sessão que NÃO foi cancelada -----------------
-- Finalize a transação normalmente:
COMMIT;
-- ou ROLLBACK, conforme o teste pedir.

-- ----------------- Na sessão que FOI cancelada -----------------
-- Após o erro "deadlock detected", o PostgreSQL já desfez essa
-- transação automaticamente. Ainda assim, execute:
ROLLBACK;
-- para garantir que a sessão volte a um estado limpo antes de
-- iniciar qualquer novo comando.


-- ----------------- VERIFICAÇÃO E REGISTRO -----------------
-- Anote no relatório da atividade:
--  - Qual sessão recebeu o erro "deadlock detected"
--  - O texto completo da mensagem de erro
--  - Se a ordem de aquisição dos locks (10A depois 10B em uma
--    sessão, 10B depois 10A na outra) foi de fato a causa
SELECT id, status FROM assentos WHERE id IN (1, 2);


-- ############################################################
-- RESET final (deixa o ambiente limpo para outros testes)
-- ############################################################
DELETE FROM reservas WHERE assento_id IN (1, 2);
UPDATE assentos SET status = 'DISPONIVEL' WHERE id IN (1, 2);
