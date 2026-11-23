# Respostas - Migrations no projeto do aeroporto

## Adaptação ao meu esquema
A tabela `voos` do projeto não tem a coluna `origem` (tem `numero_voo`,
`destino`, `portao`, `horario`, `status`). Como o enunciado permite, a coluna
renomeada no expandir e contrair foi **`destino` -> `aeroporto_destino`**
(`VARCHAR(100)`, o mesmo tamanho da original):

| Enunciado | Neste projeto |
|---|---|
| `003_add_aeroporto_origem.sql` | `003_add_aeroporto_destino.sql` |
| `004_drop_origem.sql` | `004_drop_destino.sql` |
| `backfill_origem.php` | `backfill_destino.php` |

## Parte 2 - Pergunta 1
Se `portao_embarque` fosse `NOT NULL` sem valor padrão, o `ALTER` até passaria
(as linhas existentes receberiam `''`), mas o código antigo, cujo `INSERT` não
lista essa coluna, passaria a falhar em todo cadastro de voo com o erro 1364
`Field 'portao_embarque' doesn't have a default value` (em modo estrito, que é
o padrão do MySQL 8). Ou seja, uma migration que só adiciona coluna precisa ser
compatível com o código que ainda está no ar: a coluna deve aceitar `NULL` ou
ter `DEFAULT`.

## Parte 3 - Passo 3: troca do código (como foi feita)
O código passa por três estados, sempre com a coluna nova já criada (passo 1)
e preenchida (passo 2):

**A) Escrever nos dois campos** (enquanto o código antigo ainda pode estar no ar):
```php
// criar()
"INSERT INTO voos (numero_voo, destino, aeroporto_destino, portao, horario, status)
 VALUES (:numero_voo, :destino, :aeroporto_destino, :portao, :horario, :status)"
// ... ':destino' => $dados['destino'], ':aeroporto_destino' => $dados['destino']

// editar()
"UPDATE voos SET numero_voo = :numero_voo, destino = :destino,
        aeroporto_destino = :aeroporto_destino, ... WHERE id = :id"
```
Depois de publicar este estado, rode o `backfill_destino.php` de novo: voos
criados pelo código antigo entre o passo 1 e esta publicação ficaram com
`aeroporto_destino` vazio.

**B) Ler só da coluna nova:** todas as consultas passam a usar
`aeroporto_destino` (no projeto, com o apelido `aeroporto_destino AS destino`,
então controllers e views não mudam). Teste listar, criar, editar, excluir e
restaurar.

**C) Parar de escrever na coluna antiga**, só depois de nenhuma instância do
código antigo estar no ar. Este é o estado do `models/Voo.php` entregue: usa
apenas `aeroporto_destino` e **só funciona em um banco que já passou pelas
migrations 003 e 004**. Para testar a aplicação no banco de cópia, defina
`DB_NAME=aeroporto_lab` (veja o `README.md`).

## Parte 3 - Pergunta 2
O `down` da `004` recria a coluna `destino`, mas **vazia (`NULL`) e sem o
`NOT NULL` original**: ele desfaz a estrutura, não os dados apagados. Para
recuperar, enquanto `aeroporto_destino` ainda existir basta copiar de volta
(`UPDATE voos SET destino = aeroporto_destino`, em lotes); se ela também tiver
sido perdida, só resta restaurar do backup (`mysqldump`).

## Parte 4

**1. Lag.** Um único `UPDATE` sem `LIMIT` em 5 milhões de voos vira uma só
transação enorme. No primário, ela mantém travadas milhões de linhas pelo
tempo todo (outras escritas esperam ou dão timeout) e gera muito log de
desfazer e de replicação. As réplicas só recebem e aplicam essa transação
depois que ela termina no primário e aplicam tudo de uma vez, então ficam
atrasadas (lag) por muito tempo: leituras nelas devolvem dados velhos e uma
troca de primário nesse período perderia ou atrasaria dados. Em lotes de 1000
linhas, com pausa, cada transação é curta e as réplicas acompanham.

**2. Ordem.** O passo 3 precisa vir **depois do 1** porque o código novo usa a
coluna `aeroporto_destino`; sem ela, toda consulta falharia com "unknown
column". E precisa vir **antes do 4** porque, se a coluna antiga fosse apagada
primeiro, o código que ainda a usa (as instâncias antigas durante uma
publicação gradual, ou o próprio código antes da troca) quebraria no mesmo
instante. Enquanto as duas colunas existem, código antigo e novo funcionam
juntos.

**3. Imutabilidade.** A `002` já foi registrada em `schema_migrations` nos
outros ambientes e **não roda de novo** ali; editar o arquivo deixaria quem já
aplicou com `VARCHAR(5)` e quem aplicar depois com `VARCHAR(10)`, bancos
diferentes com o mesmo "número de versão" e um histórico que não reproduz o
estado real. Cria-se uma migration nova, a `005_alter_portao_embarque_tamanho.sql`:
```sql
-- up
ALTER TABLE voos MODIFY COLUMN portao_embarque VARCHAR(10) NULL;

-- down
ALTER TABLE voos MODIFY COLUMN portao_embarque VARCHAR(5) NULL;
```
(O `down` falha, ou trunca dados, se já houver valores com mais de 5 caracteres.)

**4. Backup.** O **passo 4 (contrair)** é o irreversível: `DROP COLUMN` apaga
os dados da coluna antiga, e o `down` só devolve uma coluna vazia. Os passos
1 e 3 são desfeitos sem perda, e o passo 2 só copia dados (a coluna antiga
continua intacta). Depois que o código novo passa a gravar só na coluna nova,
a antiga fica desatualizada, então voltar a ela também perderia os dados
recentes. Por isso se faz backup antes do passo 4.
