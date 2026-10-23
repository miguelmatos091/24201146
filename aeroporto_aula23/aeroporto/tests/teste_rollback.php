<?php

/**
 * Desafio extra 2: simula uma falha DEPOIS do UPDATE e prova que o rollback
 * desfaz a exclusão. Execute no terminal:  php tests/teste_rollback.php [id]
 */

require_once __DIR__ . '/../models/Voo.php';

$id  = (int) ($argv[1] ?? 1);
$db  = Database::conectar();
$voo = new Voo();

$contaLogs = fn(): int => (int) $db->query("SELECT COUNT(*) FROM auditoria")->fetchColumn();

if ($voo->buscar($id) === null) {
    exit("Voo $id não está ativo. Restaure-o ou escolha outro id.\n");
}

$logsAntes = $contaLogs();
echo "Antes: voo $id ativo = sim | linhas em auditoria = $logsAntes\n";

try {
    $voo->excluir($id, 1, function () {
        throw new RuntimeException('Falha simulada depois do UPDATE');
    });
} catch (Throwable $e) {
    echo "Erro capturado: " . $e->getMessage() . "\n";
}

$ativoDepois = $voo->buscar($id) !== null;
$logsDepois  = $contaLogs();
echo "Depois: voo $id ativo = " . ($ativoDepois ? 'sim' : 'não') . " | linhas em auditoria = $logsDepois\n";

echo ($ativoDepois && $logsDepois === $logsAntes)
    ? "OK: rollback desfez o UPDATE (deleted_at continua NULL) e nada foi auditado.\n"
    : "FALHA: o rollback não funcionou.\n";
