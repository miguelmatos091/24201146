<?php

/**
 * Front controller: único ponto de entrada da aplicação.
 * Acesse: http://localhost/aeroporto/public/index.php
 *
 * Aula 25: tudo, exceto login/logout, exige usuário autenticado.
 * Qualquer erro inesperado (inclusive de conexão com o banco) é registrado
 * no log e a tela mostra só uma mensagem genérica.
 */

ini_set('session.use_strict_mode', '1');
session_set_cookie_params(['httponly' => true, 'samesite' => 'Lax']);
session_start();

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../controllers/VooController.php';

$acao = $_GET['acao'] ?? 'listar';

try {
    switch ($acao) {
        case 'login':
            (new AuthController())->login();
            break;

        case 'logout':
            (new AuthController())->logout();
            break;

        default:
            exigirLogin();
            $controller = new VooController();

            switch ($acao) {
                case 'listar':    $controller->listar();    break;
                case 'novo':      $controller->novo();      break;
                case 'salvar':    $controller->salvar();    break;
                case 'editar':    $controller->editar();    break;
                case 'atualizar': $controller->atualizar(); break;
                case 'excluir':   $controller->excluir();   break;
                case 'excluidos': $controller->excluidos(); break;
                case 'restaurar': $controller->restaurar(); break;
                case 'buscar':    $controller->buscar();    break;
                default:
                    http_response_code(404);
                    echo 'Página não encontrada.';
            }
    }
} catch (Throwable $e) {
    error_log('[aeroporto] ' . $e->getMessage());
    http_response_code(500);
    echo 'Ocorreu um erro. Tente novamente mais tarde.';
}
