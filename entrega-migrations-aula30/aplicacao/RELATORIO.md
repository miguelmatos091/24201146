# Relatório - Soft Delete de voos

## Como o filtro de registros ativos foi garantido
Todo o SQL de voos está no model `Voo`, e o filtro `deleted_at IS NULL` existe
em um único lugar: a constante privada `Voo::ATIVO`. `listar()`, `buscar()` e
`editar()` a concatenam na consulta; nenhuma view ou controller escreve SQL,
então não há como "esquecer" o filtro em uma tela. Por consequência, um voo
excluído não aparece na listagem, não abre na edição e não pode ser alterado
por URL (`?acao=editar&id=N` devolve "Voo não encontrado"). A única consulta
que olha os excluídos é `listarExcluidos()` (`deleted_at IS NOT NULL`), usada
na tela "Voos excluídos". A coluna `deleted_at` tem índice, porque todas as
listagens filtram por ela.

## Como a atomicidade da exclusão com a auditoria foi tratada
`excluir()` abre uma transação (`beginTransaction`) e, dentro dela: (1) lê o
voo com `SELECT ... FOR UPDATE`, que trava a linha e guarda os dados antes da
alteração; (2) executa o `UPDATE ... SET deleted_at = NOW()`; (3) insere o
registro em `auditoria` (tabela, id, ação, usuário e `dados_antes` em JSON);
(4) faz `commit`. Qualquer exceção em qualquer passo cai no `catch`, que
executa `rollBack()` e relança o erro; o controller mostra "Nada foi
alterado". O PDO está em `ERRMODE_EXCEPTION`, então uma falha na gravação do
log vira exceção e desfaz também o `UPDATE`. A restauração segue o mesmo
padrão. `tests/teste_rollback.php` simula uma falha entre o `UPDATE` e o log e
mostra que o voo continua ativo e que a auditoria não ganhou linhas.

## Desafio extra 3: backup e restauração
```bash
# 1) backup (o dump já inclui deleted_at e a tabela auditoria)
mysqldump -u root -p --single-transaction --routines --triggers aeroporto > backup_aeroporto.sql

# 2) banco de teste com cópia dos dados
mysql -u root -p -e "CREATE DATABASE aeroporto_teste"
mysql -u root -p aeroporto_teste < backup_aeroporto.sql

# 3) apagar DEFINITIVAMENTE um voo no banco de teste
mysql -u root -p aeroporto_teste -e "DELETE FROM voos WHERE id = 5"

# 4) restaurar o voo a partir do backup, sem sobrescrever o resto
mysql -u root -p -e "CREATE DATABASE aeroporto_backup"
mysql -u root -p aeroporto_backup < backup_aeroporto.sql
mysql -u root -p -e "INSERT INTO aeroporto_teste.voos SELECT * FROM aeroporto_backup.voos WHERE id = 5"
```
**Diferença:** o soft delete recupera um registro isolado de forma instantânea
(basta `deleted_at = NULL`), mas só protege contra exclusão acidental feita
pela aplicação; se alguém roda `DELETE`, apaga a tabela ou o banco é perdido,
ele não ajuda. O backup protege contra perda de dados em qualquer escala, mas
recupera apenas o estado do momento em que foi gerado (alterações posteriores
se perdem) e a restauração é mais trabalhosa.

## Desafio extra 1 (voo com reservas ativas)
Não implementado: o esquema do aeroporto usado nesta atividade só tem a tabela
`voos`, sem reservas.
