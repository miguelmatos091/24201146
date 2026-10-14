<?php

require_once __DIR__ . '/../models/Voo.php';

/**
 * Controller de Voos: recebe a requisição, valida a entrada,
 * chama o model e escolhe qual view mostrar. Não contém SQL.
 */
class VooController
{
    private Voo $voo;

    public function __construct()
    {
        $this->voo = new Voo();
    }

    // GET ?acao=listar
    public function listar(): void
    {
        $titulo = 'Voos';
        try {
            $voos = $this->voo->listar();
        } catch (PDOException $e) {
            $voos = [];
            $this->flash('erro', $this->mensagemErro($e));
        }
        require __DIR__ . '/../views/voos/listar.php';
    }

    // GET ?acao=novo
    public function novo(): void
    {
        $voo    = $this->vazio();
        $erros  = [];
        $titulo = 'Novo voo';
        require __DIR__ . '/../views/voos/criar.php';
    }

    // POST ?acao=salvar
    public function salvar(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar();
        }

        [$dados, $erros] = $this->validar($_POST);

        if (!$erros) {
            try {
                $this->voo->criar($dados);
                $this->flash('sucesso', 'Voo cadastrado com sucesso.');
                $this->redirecionar();
            } catch (PDOException $e) {
                $erros[] = $this->mensagemErro($e);
            }
        }

        // Houve erro: reexibe o formulário com os dados digitados.
        $voo    = $dados;
        $titulo = 'Novo voo';
        require __DIR__ . '/../views/voos/criar.php';
    }

    // GET ?acao=editar&id=N
    public function editar(): void
    {
        $id  = (int) ($_GET['id'] ?? 0);
        $voo = $this->buscarOuSair($id);

        $erros  = [];
        $titulo = 'Editar voo';
        require __DIR__ . '/../views/voos/editar.php';
    }

    // POST ?acao=atualizar&id=N
    public function atualizar(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar();
        }

        $id = (int) ($_GET['id'] ?? 0);
        $this->buscarOuSair($id);

        [$dados, $erros] = $this->validar($_POST);

        if (!$erros) {
            try {
                $this->voo->editar($id, $dados);
                $this->flash('sucesso', 'Voo atualizado com sucesso.');
                $this->redirecionar();
            } catch (PDOException $e) {
                $erros[] = $this->mensagemErro($e);
            }
        }

        $voo       = $dados;
        $voo['id'] = $id;
        $titulo    = 'Editar voo';
        require __DIR__ . '/../views/voos/editar.php';
    }

    // POST ?acao=excluir (campo id no corpo do POST)
    public function excluir(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar();
        }

        $id = (int) ($_POST['id'] ?? 0);

        try {
            $this->voo->excluir($id);
            $this->flash('sucesso', 'Voo excluído.');
        } catch (PDOException $e) {
            // Ex.: restrição de chave estrangeira ou trigger que bloqueia a exclusão.
            $this->flash('erro', $this->mensagemErro($e));
        }

        $this->redirecionar();
    }

    // ---------------------------------------------------------------
    // Auxiliares privados
    // ---------------------------------------------------------------

    private function vazio(): array
    {
        return [
            'id'         => null,
            'numero_voo' => '',
            'destino'    => '',
            'portao'     => '',
            'horario'    => '',
            'status'     => 'Aguardando',
        ];
    }

    /** Busca o voo; se não existir, avisa e volta para a listagem. */
    private function buscarOuSair(int $id): array
    {
        $voo = $id > 0 ? $this->voo->buscar($id) : null;

        if ($voo === null) {
            $this->flash('erro', 'Voo não encontrado.');
            $this->redirecionar();
        }

        return $voo;
    }

    /**
     * Valida e normaliza a entrada.
     * @return array{0: array, 1: string[]} [dados, erros]
     */
    private function validar(array $entrada): array
    {
        $erros = [];

        $numero  = trim((string) ($entrada['numero_voo'] ?? ''));
        $destino = trim((string) ($entrada['destino'] ?? ''));
        $portao  = trim((string) ($entrada['portao'] ?? ''));
        $horario = trim((string) ($entrada['horario'] ?? ''));
        $status  = trim((string) ($entrada['status'] ?? ''));

        if (!ctype_digit($numero) || (int) $numero < 1 || (int) $numero > 2147483647) {
            $erros[] = 'Número do voo deve ser um inteiro positivo.';
        }

        if ($destino === '' || mb_strlen($destino) > 100) {
            $erros[] = 'Destino é obrigatório (máximo de 100 caracteres).';
        }

        if (mb_strlen($portao) > 10) {
            $erros[] = 'Portão deve ter no máximo 10 caracteres.';
        }

        if (!preg_match('/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/', $horario)) {
            $erros[] = 'Horário inválido (use HH:MM).';
        }

        if (!in_array($status, Voo::STATUS_VALIDOS, true)) {
            $erros[] = 'Status inválido.';
        }

        $dados = [
            'numero_voo' => $numero,
            'destino'    => $destino,
            'portao'     => $portao === '' ? null : $portao,
            'horario'    => $horario,
            'status'     => $status,
        ];

        return [$dados, $erros];
    }

    /** Traduz exceções do PDO em mensagens amigáveis. */
    private function mensagemErro(PDOException $e): string
    {
        $sqlstate = $e->errorInfo[0] ?? (string) $e->getCode();

        // Mensagem de SIGNAL em triggers (ex.: portão em manutenção).
        if ($sqlstate === '45000') {
            return $e->errorInfo[2] ?? 'Operação bloqueada por regra do banco.';
        }

        // Violação de integridade (chave estrangeira, duplicidade).
        if ($sqlstate === '23000') {
            return 'Operação não permitida: há registros vinculados a este voo ou o dado já existe.';
        }

        error_log('[aeroporto] ' . $e->getMessage());
        return 'Erro ao acessar o banco de dados.';
    }

    private function flash(string $tipo, string $mensagem): void
    {
        $_SESSION['flash'] = ['tipo' => $tipo, 'mensagem' => $mensagem];
    }

    private function redirecionar(): void
    {
        header('Location: index.php?acao=listar');
        exit;
    }
}
