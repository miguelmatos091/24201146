<?php
// api/alunos.php — Versão 2: o PHP aplica a regra de negócio e devolve o status.
require __DIR__ . '/../../config.php';

const NOTA_MINIMA_APROVACAO = 7.0;

function calcularStatus(float $nota): string
{
    return $nota >= NOTA_MINIMA_APROVACAO ? 'Aprovado' : 'Reprovado';
}

header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $pdo->prepare('SELECT id, nome, nota FROM alunos ORDER BY nome');
    $stmt->execute();

    $resposta = [];
    foreach ($stmt->fetchAll() as $a) {
        $nota = (float) $a['nota'];
        $resposta[] = [
            'id'     => (int) $a['id'],
            'nome'   => $a['nome'],
            'nota'   => $nota,
            'status' => calcularStatus($nota),   // regra de negócio no backend
        ];
    }

    echo json_encode($resposta, JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['erro' => 'Erro ao consultar os alunos.']);
}
