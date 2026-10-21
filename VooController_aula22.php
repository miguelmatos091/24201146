<?php
require_once __DIR__ . '/../models/Voo_aula20_aula22.php';

class VooController
{
    private Voo $voo;

    public function __construct(PDO $db)
    {
        $this->voo = new Voo($db);
        if (session_status() === PHP_SESSION_NONE) session_start();
    }

    private function usuarioId(): int
    {
        return (int)($_SESSION['usuario_id'] ?? 0); // ajuste ao seu login
    }

    private function redirecionar(string $url, string $tipo, string $msg): void
    {
        $_SESSION['flash'] = ['tipo' => $tipo, 'msg' => $msg];
        header("Location: $url");
        exit;
    }

    public function index(): void
    {
        $voos = $this->voo->listar();
        require __DIR__ . '/../views/voos_lista_aula20_aula22.php';
    }

    public function excluidos(): void
    {
        $voos = $this->voo->listarExcluidos();
        require __DIR__ . '/../views/voos_excluidos_aula20_aula22.php';
    }

    // Só aceita POST (nunca excluir por link GET)
    public function excluir(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar('index.php', 'erro', 'Método inválido.');
        }
        $id = (int)($_POST['id'] ?? 0);
        try {
            $ok = $this->voo->excluir($id, $this->usuarioId());
            $ok ? $this->redirecionar('index.php', 'sucesso', 'Voo excluído com sucesso.')
                : $this->redirecionar('index.php', 'erro', 'Voo não encontrado.');
        } catch (Throwable $e) {
            error_log($e->getMessage());
            $this->redirecionar('index.php', 'erro', 'Erro ao excluir. Nada foi alterado.');
        }
    }

    public function restaurar(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar('excluidos.php', 'erro', 'Método inválido.');
        }
        $id = (int)($_POST['id'] ?? 0);
        try {
            $ok = $this->voo->restaurar($id, $this->usuarioId());
            $ok ? $this->redirecionar('excluidos.php', 'sucesso', 'Voo restaurado.')
                : $this->redirecionar('excluidos.php', 'erro', 'Voo não encontrado entre os excluídos.');
        } catch (Throwable $e) {
            error_log($e->getMessage());
            $this->redirecionar('excluidos.php', 'erro', 'Erro ao restaurar.');
        }
    }
}
