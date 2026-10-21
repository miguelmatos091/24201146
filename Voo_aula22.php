<?php
// Ajuste a forma de obter o PDO ao que seu projeto já usa.
class Voo
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
        $this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    }

    // Filtro centralizado: toda consulta de voos ativos usa esta constante
    private const ATIVOS = 'deleted_at IS NULL';

    public function listar(): array
    {
        return $this->db->query(
            'SELECT * FROM voos WHERE ' . self::ATIVOS . ' ORDER BY horario'
        )->fetchAll(PDO::FETCH_ASSOC);
    }

    public function buscar(int $id): ?array
    {
        $st = $this->db->prepare(
            'SELECT * FROM voos WHERE id = :id AND ' . self::ATIVOS
        );
        $st->execute([':id' => $id]);
        return $st->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    public function listarExcluidos(): array
    {
        return $this->db->query(
            'SELECT * FROM voos WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC'
        )->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Soft delete + auditoria na MESMA transação.
     * $falharAposUpdate serve só para o desafio extra 2 (simular erro).
     */
    public function excluir(int $id, int $usuarioId, bool $falharAposUpdate = false): bool
    {
        $this->db->beginTransaction();
        try {
            $voo = $this->buscar($id);
            if (!$voo) {
                $this->db->rollBack();
                return false; // não existe ou já excluído
            }

            $st = $this->db->prepare(
                'UPDATE voos SET deleted_at = NOW() WHERE id = :id AND deleted_at IS NULL'
            );
            $st->execute([':id' => $id]);

            if ($falharAposUpdate) {
                throw new RuntimeException('Falha simulada após o UPDATE');
            }

            $log = $this->db->prepare(
                'INSERT INTO auditoria (tabela, registro_id, acao, usuario_id, dados_antes)
                 VALUES (:t, :r, :a, :u, :d)'
            );
            $log->execute([
                ':t' => 'voos',
                ':r' => $id,
                ':a' => 'SOFT_DELETE',
                ':u' => $usuarioId,
                ':d' => json_encode($voo, JSON_UNESCAPED_UNICODE),
            ]);

            $this->db->commit();
            return true;
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    public function restaurar(int $id, int $usuarioId): bool
    {
        $this->db->beginTransaction();
        try {
            $st = $this->db->prepare(
                'UPDATE voos SET deleted_at = NULL WHERE id = :id AND deleted_at IS NOT NULL'
            );
            $st->execute([':id' => $id]);
            if ($st->rowCount() === 0) {
                $this->db->rollBack();
                return false;
            }

            $log = $this->db->prepare(
                'INSERT INTO auditoria (tabela, registro_id, acao, usuario_id, dados_antes)
                 VALUES (\'voos\', :r, \'RESTORE\', :u, NULL)'
            );
            $log->execute([':r' => $id, ':u' => $usuarioId]);

            $this->db->commit();
            return true;
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }
}
