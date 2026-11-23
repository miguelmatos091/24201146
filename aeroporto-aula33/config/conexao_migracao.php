<?php

/**
 * Conexão usada SOMENTE pelos scripts de linha de comando (migrate.php e
 * backfill_destino.php). Migrations precisam de ALTER/CREATE/DROP, que a conta
 * da aplicação (app_aeroporto) não tem, então aqui se usa um administrador.
 *
 * Por padrão aponta para o banco de CÓPIA `aeroporto_lab`, nunca para o banco do
 * projeto. Para mudar: MIGRATE_DB_NAME, MIGRATE_DB_USER, MIGRATE_DB_PASS.
 */
function conectarMigracao(): PDO
{
    $host  = getenv('MIGRATE_DB_HOST') ?: 'localhost';
    $banco = getenv('MIGRATE_DB_NAME') ?: 'aeroporto_lab';
    $user  = getenv('MIGRATE_DB_USER') ?: 'root';
    $senha = getenv('MIGRATE_DB_PASS') ?: '';

    return new PDO(
        "mysql:host=$host;dbname=$banco;charset=utf8mb4",
        $user,
        $senha,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
}
