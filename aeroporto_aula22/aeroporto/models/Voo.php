<?php

require_once __DIR__ . '/../config/database.php';

/**
 * Model de Voos: concentra TODO o SQL relacionado à tabela `voos`.
 * Não gera HTML e não lê $_POST/$_GET: recebe dados e devolve dados.
 *
 * Exclusão lógica (soft delete): excluir() preenche `deleted_at`, nunca
 * executa DELETE. O filtro de registros ativos vive em UM só lugar (ATIVO).
 */
class Voo
{
    /** Status usados nos dados do aeroporto. */
    public const STATUS_VALIDOS = ['Aguardando', 'Confirmado', 'Embarque'];

    /** Filtro único de registros ativos: toda consulta de "voos vivos" usa esta constante. */
    private const ATIVO = 'deleted_at IS NULL';

    private const COLUNAS = 'id, numero_voo, destino, portao, horario, status';

    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    // LISTAR (somente ativos)
    public function listar(): array
    {
        $sql = "SELECT " . self::COLUNAS . "
                FROM voos
                WHERE " . self::ATIVO . "
                ORDER BY horario, id";
        return $this->db->query($sql)->fetchAll();
    }

    // LISTAR EXCLUÍDOS (tela "Voos excluídos")
    public function listarExcluidos(): array
    {
        $sql = "SELECT " . self::COLUNAS . ", deleted_at
                FROM voos
                WHERE deleted_at IS NOT NULL
                ORDER BY deleted_at DESC, id";
        return $this->db->query($sql)->fetchAll();
    }

    // BUSCAR UM (somente ativo; usado na tela de edição)
    public function buscar(int $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT " . self::COLUNAS . "
             FROM voos
             WHERE id = :id AND " . self::ATIVO
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

    // EDITAR (somente voos ativos)
    public function editar(int $id, array $dados): bool
    {
        $sql = "UPDATE voos
                SET numero_voo = :numero_voo,
                    destino    = :destino,
                    portao     = :portao,
                    horario    = :horario,
                    status     = :status
                WHERE id = :id AND " . self::ATIVO;

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

    /**
     * EXCLUIR (soft delete): marca deleted_at e grava a auditoria na MESMA
     * transação. Se qualquer passo falhar, faz rollback e relança a exceção.
     *
     * @param callable|null $aposUpdate gancho só para testes: roda depois do
     *        UPDATE e antes do log (permite simular falha no meio da exclusão).
     * @return bool false se o voo não existe ou já estava excluído.
     */
    public function excluir(int $id, ?int $usuarioId = null, ?callable $aposUpdate = null): bool
    {
        $this->db->beginTransaction();

        try {
            // FOR UPDATE trava a linha: duas exclusões simultâneas não duplicam o log.
            $stmt = $this->db->prepare(
                "SELECT " . self::COLUNAS . ", deleted_at
                 FROM voos
                 WHERE id = :id AND " . self::ATIVO . "
                 FOR UPDATE"
            );
            $stmt->execute([':id' => $id]);
            $antes = $stmt->fetch();

            if (!$antes) {
                $this->db->rollBack();
                return false;
            }

            $stmt = $this->db->prepare(
                "UPDATE voos SET deleted_at = NOW() WHERE id = :id AND " . self::ATIVO
            );
            $stmt->execute([':id' => $id]);

            if ($aposUpdate !== null) {
                $aposUpdate();
            }

            $this->auditar($id, 'SOFT_DELETE', $usuarioId, $antes);

            $this->db->commit();
            return true;
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * RESTAURAR: volta deleted_at para NULL (também auditado, na mesma transação).
     * @return bool false se o voo não existe ou não estava excluído.
     */
    public function restaurar(int $id, ?int $usuarioId = null): bool
    {
        $this->db->beginTransaction();

        try {
            $stmt = $this->db->prepare(
                "SELECT " . self::COLUNAS . ", deleted_at
                 FROM voos
                 WHERE id = :id AND deleted_at IS NOT NULL
                 FOR UPDATE"
            );
            $stmt->execute([':id' => $id]);
            $antes = $stmt->fetch();

            if (!$antes) {
                $this->db->rollBack();
                return false;
            }

            $stmt = $this->db->prepare(
                "UPDATE voos SET deleted_at = NULL WHERE id = :id AND deleted_at IS NOT NULL"
            );
            $stmt->execute([':id' => $id]);

            $this->auditar($id, 'RESTORE', $usuarioId, $antes);

            $this->db->commit();
            return true;
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    // ------------------------------------------------------------------
    // AULA 23 - SQL INJECTION (laboratório)
    // ------------------------------------------------------------------

    /**
     * VERSÃO A - VULNERÁVEL (somente para o laboratório, no projeto local).
     * O texto do usuário é concatenado no SQL, então vira COMANDO.
     * >>> REMOVER este método depois da entrega da atividade. <<<
     */
    public function buscarVulneravel(string $destino): array
    {
        $sql = "SELECT id, numero_voo, destino, portao, status
                FROM voos WHERE destino = '$destino' AND " . self::ATIVO;
        return $this->db->query($sql)->fetchAll();
    }

    /** VERSÃO B - SEGURA: o texto do usuário viaja como DADO, preso ao placeholder. */
    public function buscarSeguro(string $destino): array
    {
        $stmt = $this->db->prepare(
            "SELECT id, numero_voo, destino, portao, status
             FROM voos WHERE destino = :destino AND " . self::ATIVO
        );
        $stmt->execute([':destino' => $destino]);
        return $stmt->fetchAll();
    }

    /** Grava uma linha em `auditoria` (deve ser chamado DENTRO de uma transação). */
    private function auditar(int $id, string $acao, ?int $usuarioId, array $dadosAntes): void
    {
        $stmt = $this->db->prepare(
            "INSERT INTO auditoria (tabela, registro_id, acao, usuario_id, dados_antes)
             VALUES ('voos', :registro_id, :acao, :usuario_id, :dados_antes)"
        );
        $stmt->execute([
            ':registro_id' => $id,
            ':acao'        => $acao,
            ':usuario_id'  => $usuarioId,
            ':dados_antes' => json_encode($dadosAntes, JSON_UNESCAPED_UNICODE),
        ]);
    }
}
