# Relatório – Soft Delete de Voos

**Filtro de registros ativos.** Todas as consultas de voos ativos ficam no Model `Voo` e usam a constante `ATIVOS` (`deleted_at IS NULL`), de modo que o filtro existe em um único lugar. O Controller e as Views nunca montam SQL; só chamam `listar()` e `buscar()`. Os voos excluídos têm um método próprio, `listarExcluidos()`. A coluna `deleted_at` também recebeu índice para manter as consultas rápidas.

**Atomicidade com a auditoria.** `excluir()` abre uma transação com `beginTransaction()`, faz o `UPDATE` de `deleted_at` e grava na tabela `auditoria` (usuário, data e os dados do voo em JSON) antes de chamar `commit()`. Qualquer exceção cai no `catch`, que executa `rollBack()`, então a exclusão nunca persiste sem o log. O modo de erro do PDO está em `ERRMODE_EXCEPTION`, o que garante que uma falha no INSERT interrompa o fluxo. A restauração segue o mesmo padrão. A exclusão só é aceita via POST, com `confirm()` no navegador.

**Desafio 2 (falha simulada).** Chamar `excluir($id, $usuario, true)` lança um erro depois do `UPDATE`; ao consultar o voo, `deleted_at` continua `NULL`, comprovando o rollback.

**Soft delete x backup.** O soft delete recupera um registro isolado de forma instantânea (um `UPDATE`), mas só funciona enquanto a linha existe. O backup com `mysqldump` recupera o banco inteiro (ou linhas apagadas com `DELETE`), porém exige restaurar um ponto no passado e é mais lento.
