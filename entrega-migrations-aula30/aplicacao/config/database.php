<?php

/**
 * Conexão centralizada com o banco.
 * Para trocar host, banco, usuário ou senha, edite SOMENTE este arquivo.
 *
 * Aula 24: a aplicação NÃO usa mais `root`. Ela usa a conta `app_aeroporto`,
 * criada em database/privilegios.sql com privilégios mínimos.
 * A senha vem da variável de ambiente DB_PASS; o valor padrão abaixo é só o
 * do exemplo da aula, TROQUE por uma senha sua (e na conta do MySQL também).
 */
class Database
{
    private static ?PDO $conexao = null;

    public static function conectar(): PDO
    {
        if (self::$conexao === null) {
            $host    = getenv('DB_HOST') ?: 'localhost';
            $banco   = getenv('DB_NAME') ?: 'aeroporto';
            $usuario = getenv('DB_USER') ?: 'app_aeroporto';
            $senha   = getenv('DB_PASS') ?: 'SenhaForte#123';

            self::$conexao = new PDO(
                "mysql:host=$host;dbname=$banco;charset=utf8mb4",
                $usuario,
                $senha,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
        }

        return self::$conexao;
    }
}
