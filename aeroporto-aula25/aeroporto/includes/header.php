<?php
$flash  = $_SESSION['flash'] ?? null;
unset($_SESSION['flash']);
$logado = !empty($_SESSION['usuario_id']);
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= htmlspecialchars($titulo ?? 'Aeroporto') ?> - Aeroporto</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
<header class="topo">
  <h1>Aeroporto</h1>
  <?php if ($logado): ?>
  <nav>
    <a href="index.php?acao=listar">Voos</a>
    <a href="index.php?acao=novo">Novo voo</a>
    <a href="index.php?acao=excluidos">Voos excluídos</a>
    <a href="index.php?acao=buscar">Buscar</a>
    <form method="post" action="index.php?acao=logout">
      <span class="usuario"><?= htmlspecialchars($_SESSION['email'] ?? '') ?></span>
      <button type="submit" class="sair">Sair</button>
    </form>
  </nav>
  <?php endif; ?>
</header>
<main>
<?php if ($flash): ?>
  <p class="aviso <?= htmlspecialchars($flash['tipo']) ?>"><?= htmlspecialchars($flash['mensagem']) ?></p>
<?php endif; ?>
