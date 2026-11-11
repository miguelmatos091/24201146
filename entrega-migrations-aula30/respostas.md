# Respostas — Atividade prática: migrations no projeto do aeroporto

**Aluno:** Miguel Matos de Sá · **Disciplina:** Banco de Dados (IDP)

## Adaptações feitas (previstas no enunciado)

- A tabela `voos` do projeto **não tem a coluna `origem`**. Usei `destino` e o renome feito foi
  **`destino` → `aeroporto_destino`**. Por isso os arquivos se chamam
  `003_add_aeroporto_destino.sql`, `004_drop_destino.sql` e `backfill_destino.php`
  (equivalentes a `003_add_aeroporto_origem`, `004_drop_origem` e `backfill_origem`).
- `destino` era `NOT NULL`. Na `003` a mesma instrução também faz `MODIFY destino VARCHAR(100) NULL`,
  senão o código novo (que passa a gravar só `aeroporto_destino`) não conseguiria inserir voos
  antes da `004` (erro 1364).
- O backfill ganhou `AND destino IS NOT NULL`; sem isso, linhas com `destino` NULL casariam para sempre
  e o `do/while` nunca terminaria.
- **Correção no runner:** com o `exec()` do enunciado, a `001_baseline` (`SELECT 1;`) deixa um resultado
  pendente e o `INSERT` em `schema_migrations` falha com o erro 2014. Troquei por `query()` + `closeCursor()`.
- Tudo foi testado em um MariaDB 10.11 local (banco `aeroporto_lab`, copiado do `aeroporto` pelo
  `mysqldump`). O comportamento é o mesmo do MySQL para estes comandos.

## Pergunta 1

Se `portao_embarque` fosse `NOT NULL` sem valor padrão, o código antigo quebraria: o `INSERT` do
`Voo::criar()` não menciona a coluna, e no modo estrito (padrão do MySQL) o banco recusa com
`ERROR 1364: Field 'portao_embarque' doesn't have a default value`. **Nenhum voo novo poderia ser criado.**
Além disso, as linhas já existentes receberiam `''` (string vazia) silenciosamente. Testei isso no
laboratório. Com `NULL`, o código antigo continua funcionando sem saber que a coluna existe.

## Pergunta 2

Ao rodar `php migrate.php down` depois da `004`, a coluna `destino` **volta, mas vazia**: no teste,
as 35 linhas ficaram com `destino` preenchido em 0 e `aeroporto_destino` em 35.
O `down` desfaz só a **estrutura**; ele **não consegue desfazer os dados** que estavam na coluna removida.
Para recuperá-los, como o backfill os copiou para a coluna nova, basta
`UPDATE voos SET destino = aeroporto_destino;` (testei: voltou a 35 de 35). Se a coluna nova já tivesse
divergido, a fonte seria o backup (`aeroporto_backup.sql`).

## Parte 4

**1. Lag.** Um único `UPDATE` sem `LIMIT` em 5 milhões de linhas é uma transação enorme. No primário
ela segura locks de linha por muito tempo (outras escritas esperam ou dão timeout) e infla o undo log e
o binlog. Nas réplicas, o evento só é aplicado depois do commit e de forma sequencial, então elas ficam
**minutos atrasadas** (replication lag) e servem dados velhos para quem lê delas. Em lotes de 1000 com
pausa, cada transação é curta e as réplicas acompanham.

**2. Ordem.** O passo 3 vem **depois do 1** porque o código novo grava e lê `aeroporto_destino`; se a
coluna ainda não existe, toda consulta falha. Vem **antes do 4** porque, se o `destino` for removido
com algum servidor ainda usando o código antigo, esse servidor passa a errar na hora. Em produção, versão
antiga e nova do código convivem durante o deploy, então o banco precisa aceitar as duas.

**3. Imutabilidade.** Depois que a `002` foi aplicada, o nome dela está em `schema_migrations` nos outros
ambientes e o runner não a roda de novo. Editar o arquivo não altera esses bancos, e os ambientes
divergem (o novo teria `VARCHAR(10)`, os antigos `VARCHAR(5)`), além de perder o histórico do que
realmente rodou. A correção é uma migration nova:

```sql
-- 005_aumentar_portao_embarque.sql
-- up
ALTER TABLE voos MODIFY portao_embarque VARCHAR(10) NULL;

-- down
ALTER TABLE voos MODIFY portao_embarque VARCHAR(5) NULL;
```

(o `down` falha ou trunca se já houver valores com mais de 5 caracteres).

**4. Backup.** O **passo 4 (contrair)** é o irreversível: `DROP COLUMN` apaga os dados da coluna. O `down`
só recria uma coluna vazia. Os passos 1 e 3 se desfazem sem perda e o passo 2 é só uma cópia, então os
dados originais continuam na coluna antiga. Só depois do passo 4 é que a única cópia pode estar em
outro lugar, ou seja, o backup.

## Observação sobre o `down` da 003

O `down` da `003` volta `destino` para `NOT NULL`; ele falha se alguma linha tiver `destino` NULL
(aconteceu no teste logo depois de desfazer a 004, antes de recuperar os dados). Nesse caso rode primeiro o
`UPDATE` de recuperação da Pergunta 2. A falha não altera nada, porque o `ALTER` é uma instrução só.
