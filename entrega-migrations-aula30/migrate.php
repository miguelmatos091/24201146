<?php
// Uso: php migrate.php up    (aplica as pendentes)
//      php migrate.php down  (desfaz a última aplicada)

$pdo = new PDO(
    'mysql:host=' . (getenv('DB_HOST') ?: 'localhost') . ';dbname=' . (getenv('DB_NAME') ?: 'aeroporto_lab') . ';charset=utf8mb4',
    getenv('DB_USER') ?: 'root',
    getenv('DB_PASS') ?: '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(100) PRIMARY KEY,
    aplicada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)");

// Separa o arquivo em duas partes: antes e depois da linha "-- down"
function separar(string $sql): array {
    $partes = preg_split('/^-- down\s*$/m', $sql);
    return [trim($partes[0]), trim($partes[1] ?? '')];
}

// Executa uma instrução e descarta qualquer resultado. Usamos query() +
// closeCursor() em vez de exec() porque a 001 roda "SELECT 1": o exec() deixa
// o resultado pendente e o INSERT seguinte falha (erro 2014).
function rodar(PDO $pdo, string $sql): void {
    $pdo->query($sql)->closeCursor();
}

$comando = $argv[1] ?? 'up';

if ($comando === 'up') {
    $aplicadas = $pdo->query("SELECT version FROM schema_migrations")
                     ->fetchAll(PDO::FETCH_COLUMN);
    $arquivos = glob(__DIR__ . '/migrations/*.sql');
    sort($arquivos);

    foreach ($arquivos as $arquivo) {
        $versao = basename($arquivo, '.sql');
        if (in_array($versao, $aplicadas)) {
            continue;
        }
        [$up] = separar(file_get_contents($arquivo));
        rodar($pdo, $up);
        $pdo->prepare("INSERT INTO schema_migrations (version) VALUES (?)")
            ->execute([$versao]);
        echo "Aplicada: $versao\n";
    }
} elseif ($comando === 'down') {
    $ultima = $pdo->query(
        "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"
    )->fetchColumn();

    if (!$ultima) {
        echo "Nada a desfazer.\n";
        exit;
    }
    [, $down] = separar(file_get_contents(__DIR__ . "/migrations/$ultima.sql"));
    rodar($pdo, $down);
    $pdo->prepare("DELETE FROM schema_migrations WHERE version = ?")
        ->execute([$ultima]);
    echo "Desfeita: $ultima\n";
}
