<?php

require_once __DIR__ . '/../models/Usuario.php';

/** Login e logout. */
class AuthController
{
    private Usuario $usuarios;

    public function __construct()
    {
        $this->usuarios = new Usuario();
    }

    // GET ?acao=login (formulário) | POST ?acao=login (processa)
    public function login(): void
    {
        if (!empty($_SESSION['usuario_id'])) {
            header('Location: index.php?acao=listar');
            exit;
        }

        $erro  = null;
        $email = '';

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $email = trim((string) ($_POST['email'] ?? ''));
            $senha = (string) ($_POST['senha'] ?? '');

            try {
                $usuario = $this->usuarios->autenticar($email, $senha);

                if ($usuario !== null) {
                    session_regenerate_id(true); // evita fixação de sessão
                    $_SESSION['usuario_id'] = (int) $usuario['id'];
                    $_SESSION['email']      = $usuario['email'];
                    $_SESSION['perfil']     = $usuario['perfil'];

                    header('Location: index.php?acao=listar');
                    exit;
                }

                // Mesma mensagem para e-mail inexistente e senha errada.
                $erro = 'E-mail ou senha inválidos';
            } catch (PDOException $e) {
                error_log('[aeroporto] ' . $e->getMessage());
                $erro = 'Não foi possível entrar agora. Tente novamente.';
            }
        }

        $titulo = 'Entrar';
        require __DIR__ . '/../views/auth/login.php';
    }

    // POST ?acao=logout
    public function logout(): void
    {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $_SESSION = [];

            if (ini_get('session.use_cookies')) {
                $p = session_get_cookie_params();
                setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
            }

            session_destroy();
        }

        header('Location: index.php?acao=login');
        exit;
    }
}
