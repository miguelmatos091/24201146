# Regras de Integridade do Banco de Dados — `aeroporto`

## 1. Banco de dados utilizado

Esta atividade foi realizada sobre o mesmo banco de dados desenvolvido pelo grupo desde o
início do semestre (`aeroporto`), na sua versão atual — o modelo normalizado obtido em
`sql_normalizado.sql`, com as tabelas `destinos` e `voos`. Não foi criado nenhum banco fictício
ou exemplo paralelo.

```text
destinos
├── id_destino (PK)
└── cidade (UNIQUE)

voos
├── id (PK)
├── numero_voo (UNIQUE)
├── id_destino (FK → destinos.id_destino)
├── portao
├── horario
└── status
```

---

## 2. Regras de integridade identificadas e justificativas

### 2.1 Integridade de entidade

Toda tabela precisa ter uma chave primária que identifique cada linha de forma única e não
nula.

- `destinos.id_destino` — `PRIMARY KEY`
- `voos.id` — `PRIMARY KEY`

**Problema que evita:** registros duplicados ou "fantasmas" sem identificador, que
inviabilizariam referenciar um voo ou destino específico de forma confiável.

### 2.2 Integridade referencial

O relacionamento `voos.id_destino → destinos.id_destino` é garantido por uma `FOREIGN KEY`.

```sql
CONSTRAINT fk_voos_destino FOREIGN KEY (id_destino)
    REFERENCES destinos (id_destino)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
```

**Problema que evita:** um voo apontar para um destino que não existe (referência órfã), e a
exclusão indevida de um destino que ainda esteja sendo usado por voos cadastrados.

- `ON DELETE RESTRICT`: impede excluir um destino enquanto houver voos vinculados a ele — está
  diretamente ligado à regra de negócio do sistema (ver item 4).
- `ON UPDATE CASCADE`: se o `id_destino` de um destino for alterado, a mudança é propagada
  automaticamente para os voos relacionados, evitando que fiquem com uma FK inválida.

### 2.3 Integridade de domínio

Cada atributo só pode assumir valores dentro de um conjunto válido para o seu significado.

- `horario TIME` — o próprio tipo de dado já restringe o valor a um horário válido.
- `numero_voo INT ... CHECK (numero_voo > 0)` — impede número de voo zero ou negativo, o que
  não existe no domínio real de numeração de voos.
- `status VARCHAR(20) ... CHECK (status IN ('Aguardando','Confirmado','Embarque','Cancelado','Pousado'))`
  — restringe o status a valores que realmente existem no fluxo operacional de um voo.

**Problema que evita:** dados sem sentido para o domínio do sistema (por exemplo, um voo com
status `"Atrasado"` — que não faz parte do fluxo modelado — ou com `numero_voo = -10`).

### 2.4 Integridade de chave (unicidade de chaves candidatas)

- `voos.numero_voo` — `UNIQUE`
- `destinos.cidade` — `UNIQUE`

**Problema que evita:** dois voos com o mesmo número (o que quebraria a identificação real de
um voo pela companhia aérea) e cidades duplicadas cadastradas com grafias/IDs diferentes.

### 2.5 Restrições de unicidade

Já cobertas nos itens 2.1 (chaves primárias) e 2.4 (`numero_voo`, `cidade`) — todas
implementadas via `PRIMARY KEY` ou `UNIQUE`.

### 2.6 Obrigatoriedade de preenchimento

- `destinos.cidade NOT NULL`
- `voos.numero_voo NOT NULL`
- `voos.id_destino NOT NULL`
- `voos.horario NOT NULL`
- `voos.status NOT NULL` (com `DEFAULT 'Aguardando'` quando não informado)

`voos.portao` foi mantido **sem** `NOT NULL` propositalmente: no sistema, um voo pode existir
antes de ter um portão de embarque definido (ex.: voo recém-criado, ainda em status
`Aguardando`), então essa ausência de valor é uma situação válida, não um erro de dados.

**Problema que evita:** voos sem número, sem destino ou sem horário — informações
indispensáveis para que o registro tenha sentido no sistema.

### 2.7 Regras relacionadas ao negócio do sistema

Ver seção 4.

---

## 3. Restrições utilizadas e onde foram aplicadas

| Restrição | Onde | Justificativa |
|---|---|---|
| `PRIMARY KEY` | `destinos.id_destino`, `voos.id` | Integridade de entidade/chave |
| `FOREIGN KEY ... ON DELETE RESTRICT ON UPDATE CASCADE` | `voos.id_destino → destinos.id_destino` | Integridade referencial + regra de negócio |
| `NOT NULL` | `cidade`, `numero_voo`, `id_destino`, `horario`, `status` | Obrigatoriedade de preenchimento |
| `UNIQUE` | `destinos.cidade`, `voos.numero_voo` | Chave candidata / regra de negócio |
| `CHECK (numero_voo > 0)` | `voos.numero_voo` | Domínio válido para número de voo |
| `CHECK (status IN (...))` | `voos.status` | Domínio válido para o fluxo operacional |
| `DEFAULT 'Aguardando'` | `voos.status` | Todo voo novo entra no sistema nesse estado inicial, sem depender do aplicativo cliente para preencher |

---

## 4. Regras de negócio implementadas

1. **Um número de voo não pode se repetir** — `numero_voo UNIQUE`. Como o número do voo é
   atribuído pela companhia aérea a uma rota específica, dois voos com o mesmo número
   representariam uma inconsistência operacional.
2. **Um voo deve estar associado a um destino existente** — `id_destino NOT NULL` + `FOREIGN KEY`.
3. **O status de um voo só pode assumir valores do fluxo real de operação** — `CHECK` em
   `status`, evitando estados inventados ou digitados incorretamente.
4. **O número do voo não pode ser zero ou negativo** — `CHECK (numero_voo > 0)`.
5. **Um destino não pode ser excluído enquanto existirem voos vinculados a ele** —
   `ON DELETE RESTRICT` na FK, evitando que voos fiquem "órfãos" (apontando para um destino
   inexistente) se alguém tentar remover uma cidade do cadastro.

---

## 5. Testes realizados

Os testes foram executados diretamente sobre o schema com as restrições aplicadas (SGBD com
suporte a `FOREIGN KEY`, `UNIQUE` e `CHECK` habilitado), usando a carga de dados completa das 30
linhas de `voos` e 9 linhas de `destinos`.

### Teste 1 — Integridade de entidade (PK duplicada)
**Situação testada:** inserir um voo com `id` já existente (`id = 1`).
```sql
INSERT INTO voos VALUES (1, 999, 2, '20', '07:00', 'Confirmado');
```
**Resultado esperado:** bloqueado por violação de chave primária.
**Resultado obtido:** bloqueado — `UNIQUE constraint failed: voos.id`.

### Teste 2 — Unicidade de `numero_voo`
**Situação testada:** inserir um voo com `numero_voo = 305`, já usado pelo voo de `id = 1`.
```sql
INSERT INTO voos VALUES (31, 305, 2, '20', '07:00', 'Confirmado');
```
**Resultado esperado:** bloqueado por violação de `UNIQUE`.
**Resultado obtido:** bloqueado — `UNIQUE constraint failed: voos.numero_voo`.

### Teste 3 — Obrigatoriedade de `id_destino`
**Situação testada:** inserir um voo sem informar o destino.
```sql
INSERT INTO voos VALUES (31, 999, NULL, '20', '07:00', 'Confirmado');
```
**Resultado esperado:** bloqueado por violação de `NOT NULL`.
**Resultado obtido:** bloqueado — `NOT NULL constraint failed: voos.id_destino`.

### Teste 4 — Integridade referencial
**Situação testada:** inserir um voo apontando para um `id_destino` que não existe (`50`).
```sql
INSERT INTO voos VALUES (31, 999, 50, '20', '07:00', 'Confirmado');
```
**Resultado esperado:** bloqueado por violação de `FOREIGN KEY`.
**Resultado obtido:** bloqueado — `FOREIGN KEY constraint failed`.

### Teste 5 — Domínio de `status`
**Situação testada:** inserir um voo com um status que não existe no fluxo do sistema.
```sql
INSERT INTO voos VALUES (31, 999, 2, '20', '07:00', 'Atrasado');
```
**Resultado esperado:** bloqueado por violação de `CHECK`.
**Resultado obtido:** bloqueado — `CHECK constraint failed: status IN (...)`.

### Teste 6 — Domínio de `numero_voo`
**Situação testada:** inserir um voo com número negativo.
```sql
INSERT INTO voos VALUES (31, -10, 2, '20', '07:00', 'Confirmado');
```
**Resultado esperado:** bloqueado por violação de `CHECK`.
**Resultado obtido:** bloqueado — `CHECK constraint failed: numero_voo > 0`.

### Teste 7 — Regra de negócio: exclusão de destino em uso
**Situação testada:** excluir o destino "Brasilia" (`id_destino = 2`), que possui vários voos
vinculados.
```sql
DELETE FROM destinos WHERE id_destino = 2;
```
**Resultado esperado:** bloqueado por `ON DELETE RESTRICT`.
**Resultado obtido:** bloqueado — `FOREIGN KEY constraint failed`.

### Teste 8 — Unicidade de `cidade`
**Situação testada:** cadastrar novamente a cidade "Brasilia" com outro `id_destino`.
```sql
INSERT INTO destinos VALUES (10, 'Brasilia');
```
**Resultado esperado:** bloqueado por violação de `UNIQUE`.
**Resultado obtido:** bloqueado — `UNIQUE constraint failed: destinos.cidade`.

### Teste 9 (controle positivo) — Inserção válida
**Situação testada:** inserir um voo novo, respeitando todas as restrições.
```sql
INSERT INTO voos VALUES (31, 999, 4, '20', '07:00', 'Confirmado');
```
**Resultado esperado:** operação executada com sucesso.
**Resultado obtido:** executada com sucesso — o SGBD não impede operações válidas.

### Teste 10 — `DEFAULT` de `status`
**Situação testada:** inserir um voo sem informar o campo `status`.
```sql
INSERT INTO voos (id, numero_voo, id_destino, portao, horario)
VALUES (32, 1000, 4, '21', '06:00');
```
**Resultado esperado:** o voo é criado com `status = 'Aguardando'` automaticamente.
**Resultado obtido:** sucesso — `(32, 1000, 'Aguardando')`.

---

## 6. Conclusão

Todas as regras de integridade identificadas (entidade, referencial, domínio, chave,
unicidade, obrigatoriedade e regras de negócio) foram implementadas usando os recursos nativos
do SGBD (`PRIMARY KEY`, `FOREIGN KEY` com `ON DELETE`/`ON UPDATE`, `NOT NULL`, `UNIQUE`, `CHECK`
e `DEFAULT`) e comprovadamente impedem a inserção ou alteração de dados inconsistentes,
enquanto continuam permitindo normalmente as operações válidas do sistema (Teste 9 e Teste 10).
O SQL correspondente está em `sql_integridade.sql`.
