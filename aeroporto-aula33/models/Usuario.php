<?php

require_once __DIR__ . '/../config/database.php';

/**
 * Model de Usuários da APLICAÇÃO (tabela `usuarios`).
 * Não confundir com as contas do SGBD (ex.: app_aeroporto, root).
 */
class Usuario
{
    /**
     * Hash de uma senha qualquer. Usado quando o e-mail não existe, para que o
     * tempo de resposta seja parecido nos dois casos (e-mail errado x senha errada).
     */
    private const HASH_FALSO = '$2y$10$yh6V4MHK1KOyiXQ8v9mUwuwCNrP5SKgUtkHPB3JZsVIWt0/RuQH9K';

    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    /**
     * Confere e-mail e senha. Devolve os dados do usuário (sem o hash)
     * ou null, sem dizer qual dos dois estava errado.
     */
    public function autenticar(string $email, string $senha): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT id, email, senha_hash, perfil FROM usuarios WHERE email = :email"
        );
        $stmt->execute([':email' => $email]);
        $usuario = $stmt->fetch();

        $hash   = $usuario['senha_hash'] ?? self::HASH_FALSO;
        $senhaOk = password_verify($senha, $hash);

        if (!$usuario || !$senhaOk) {
            return null;
        }

        unset($usuario['senha_hash']);
        return $usuario;
    }
}
