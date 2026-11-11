<?php

/**
 * Protege as páginas: sem sessão de login, vai para a tela de login.
 * O session_start() é feito uma única vez em public/index.php.
 */
function exigirLogin(): void
{
    if (empty($_SESSION['usuario_id'])) {
        header('Location: index.php?acao=login');
        exit;
    }
}

function ehAdmin(): bool
{
    return ($_SESSION['perfil'] ?? '') === 'admin';
}
