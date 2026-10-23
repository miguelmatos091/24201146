<?php

/**
 * Conexão centralizada com o banco.
 * Para trocar host, banco, usuário ou senha, edite SOMENTE este arquivo.
 */
class Database
{
    private static ?PDO $conexao = null;

    public static function conectar(): PDO
    {
        if (self::$conexao === null) {
            $host    = 'localhost';
            $banco   = 'aeroporto';
            $usuario = 'root';
            $senha   = '';

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
