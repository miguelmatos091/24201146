<?php

require_once __DIR__ . '/../config/database.php';

/**
 * Model de Voos: concentra TODO o SQL relacionado à tabela `voos`.
 * Não gera HTML e não lê $_POST/$_GET: recebe dados e devolve dados.
 */
class Voo
{
    /** Status usados nos dados do aeroporto. */
    public const STATUS_VALIDOS = ['Aguardando', 'Confirmado', 'Embarque'];

    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    // LISTAR
    public function listar(): array
    {
        $sql = "SELECT id, numero_voo, destino, portao, horario, status
                FROM voos
                ORDER BY horario, id";
        return $this->db->query($sql)->fetchAll();
    }

    // BUSCAR UM (usado na tela de edição)
    public function buscar(int $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT id, numero_voo, destino, portao, horario, status
             FROM voos WHERE id = :id"
        );
        $stmt->execute([':id' => $id]);
        $voo = $stmt->fetch();

        return $voo ?: null;
    }

    // CRIAR (o id é AUTO_INCREMENT: ver database/aeroporto.sql)
    public function criar(array $dados): bool
    {
        $sql = "INSERT INTO voos (numero_voo, destino, portao, horario, status)
                VALUES (:numero_voo, :destino, :portao, :horario, :status)";

        $stmt = $this->db->prepare($sql);

        return $stmt->execute([
            ':numero_voo' => $dados['numero_voo'],
            ':destino'    => $dados['destino'],
            ':portao'     => $dados['portao'],
            ':horario'    => $dados['horario'],
            ':status'     => $dados['status'],
        ]);
    }

    // EDITAR
    public function editar(int $id, array $dados): bool
    {
        $sql = "UPDATE voos
                SET numero_voo = :numero_voo,
                    destino    = :destino,
                    portao     = :portao,
                    horario    = :horario,
                    status     = :status
                WHERE id = :id";

        $stmt = $this->db->prepare($sql);

        return $stmt->execute([
            ':numero_voo' => $dados['numero_voo'],
            ':destino'    => $dados['destino'],
            ':portao'     => $dados['portao'],
            ':horario'    => $dados['horario'],
            ':status'     => $dados['status'],
            ':id'         => $id,
        ]);
    }

    // EXCLUIR
    public function excluir(int $id): bool
    {
        $stmt = $this->db->prepare("DELETE FROM voos WHERE id = :id");
        return $stmt->execute([':id' => $id]);
    }
}
