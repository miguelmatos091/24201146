<?php

/**
 * Front controller: único ponto de entrada da aplicação.
 * Acesse: http://localhost/aeroporto/public/index.php
 */

session_start();

require_once __DIR__ . '/../controllers/VooController.php';

$acao       = $_GET['acao'] ?? 'listar';
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
