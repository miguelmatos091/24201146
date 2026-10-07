<?php
// api/alunos.php — Versão 1: o PHP só entrega os dados (sem regra de negócio).
require __DIR__ . '/../../config.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $pdo->prepare('SELECT id, nome, nota FROM alunos ORDER BY nome');
    $stmt->execute();
    $alunos = $stmt->fetchAll();

    // DECIMAL chega como string no PDO; converte para número no JSON.
    foreach ($alunos as &$a) {
        $a['id']   = (int) $a['id'];
        $a['nota'] = (float) $a['nota'];
    }
    unset($a);

    echo json_encode($alunos, JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    error_log($e->getMessage());               // detalhe fica no log do servidor
    echo json_encode(['erro' => 'Erro ao consultar os alunos.']);
}
