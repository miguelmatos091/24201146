<?php
// Uso: php migrate.php up      (aplica as pendentes)
//      php migrate.php down    (desfaz a última aplicada)
//      php migrate.php status  (lista aplicadas e pendentes)
//
// Versão mínima do que Flyway ou Phinx fazem. Roda no banco de cópia
// `aeroporto_lab` (ver config/conexao_migracao.php).
//
// Limitações propositais:
//  - cada seção (up e down) deve ter UMA única instrução SQL;
//  - no MySQL, ALTER TABLE faz commit implícito: não há rollback automático
//    se algo falhar no meio.

if (PHP_SAPI !== 'cli') {
    exit("Execute pelo terminal: php migrate.php up\n");
}

require_once __DIR__ . '/config/conexao_migracao.php';

$pdo = conectarMigracao();

$pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(100) PRIMARY KEY,
    aplicada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)");

// Separa o arquivo em duas partes: antes e depois da linha "-- down"
function separar(string $sql): array
{
    $partes = preg_split('/^-- down\s*$/m', $sql);
    return [trim($partes[0]), trim($partes[1] ?? '')];
}

function arquivosDeMigracao(): array
{
    $arquivos = glob(__DIR__ . '/migrations/*.sql');
    sort($arquivos);
    return $arquivos;
}

$comando = $argv[1] ?? 'up';

try {
    if ($comando === 'up') {
        $aplicadas = $pdo->query("SELECT version FROM schema_migrations")
                         ->fetchAll(PDO::FETCH_COLUMN);
        $pendentes = 0;

        foreach (arquivosDeMigracao() as $arquivo) {
            $versao = basename($arquivo, '.sql');
            if (in_array($versao, $aplicadas, true)) {
                continue;
            }
            [$up] = separar(file_get_contents($arquivo));
            $pdo->exec($up);
            $pdo->prepare("INSERT INTO schema_migrations (version) VALUES (?)")
                ->execute([$versao]);
            echo "Aplicada: $versao\n";
            $pendentes++;
        }

        if ($pendentes === 0) {
            echo "Nenhuma migration pendente.\n";
        }
    } elseif ($comando === 'down') {
        $ultima = $pdo->query(
            "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"
        )->fetchColumn();

        if (!$ultima) {
            echo "Nada a desfazer.\n";
            exit;
        }

        $arquivo = __DIR__ . "/migrations/$ultima.sql";
        if (!is_file($arquivo)) {
            fwrite(STDERR, "Arquivo da migration $ultima não encontrado.\n");
            exit(1);
        }

        [, $down] = separar(file_get_contents($arquivo));
        if ($down === '') {
            fwrite(STDERR, "A migration $ultima não tem seção -- down.\n");
            exit(1);
        }

        $pdo->exec($down);
        $pdo->prepare("DELETE FROM schema_migrations WHERE version = ?")
            ->execute([$ultima]);
        echo "Desfeita: $ultima\n";
    } elseif ($comando === 'status') {
        $aplicadas = $pdo->query("SELECT version FROM schema_migrations")
                         ->fetchAll(PDO::FETCH_COLUMN);
        foreach (arquivosDeMigracao() as $arquivo) {
            $versao = basename($arquivo, '.sql');
            echo (in_array($versao, $aplicadas, true) ? '[x] ' : '[ ] ') . $versao . "\n";
        }
    } else {
        fwrite(STDERR, "Comando desconhecido: $comando (use up, down ou status)\n");
        exit(1);
    }
} catch (PDOException $e) {
    // Em linha de comando é útil ver o erro; no navegador isso nunca apareceria.
    fwrite(STDERR, "Erro na migration: " . $e->getMessage() . "\n");
    exit(1);
}
