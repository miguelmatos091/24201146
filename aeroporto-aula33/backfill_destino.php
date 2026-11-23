<?php
// Passo 2: copia destino -> aeroporto_destino em lotes de 1000 linhas.
// Uso: php backfill_destino.php
//
// Copia TODAS as linhas, inclusive as com deleted_at preenchido (soft delete),
// para que a restauração de um voo não traga o campo novo vazio.
// `destino` é NOT NULL, então o laço sempre termina; se a coluna de origem
// aceitasse NULL, o WHERE ... IS NULL nunca zeraria e seria preciso outro critério.

if (PHP_SAPI !== 'cli') {
    exit("Execute pelo terminal: php backfill_destino.php\n");
}

require_once __DIR__ . '/config/conexao_migracao.php';

$pdo = conectarMigracao();

try {
    do {
        $afetadas = $pdo->exec(
            "UPDATE voos SET aeroporto_destino = destino
              WHERE aeroporto_destino IS NULL
              LIMIT 1000"
        );
        echo "Lote: $afetadas linhas\n";
        usleep(200000); // pausa de 0,2 s para não sobrecarregar o banco
    } while ($afetadas > 0);
} catch (PDOException $e) {
    fwrite(STDERR, "Erro no backfill: " . $e->getMessage() . "\n");
    exit(1);
}
