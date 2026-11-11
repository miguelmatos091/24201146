<?php
// Passo 2 (migrar dados em lotes): copia destino -> aeroporto_destino.
// Uso: php backfill_destino.php
$pdo = new PDO(
    'mysql:host=' . (getenv('DB_HOST') ?: 'localhost') . ';dbname=' . (getenv('DB_NAME') ?: 'aeroporto_lab') . ';charset=utf8mb4',
    getenv('DB_USER') ?: 'root',
    getenv('DB_PASS') ?: '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

do {
    $afetadas = $pdo->exec(
        "UPDATE voos SET aeroporto_destino = destino
          WHERE aeroporto_destino IS NULL
            AND destino IS NOT NULL
          LIMIT 1000"
    );
    echo "Lote: $afetadas linhas\n";
    usleep(200000); // pausa de 0,2 s para não sobrecarregar o banco
} while ($afetadas > 0);
