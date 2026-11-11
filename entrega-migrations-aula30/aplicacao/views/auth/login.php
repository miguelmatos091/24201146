<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Entrar</h2>

<?php if (!empty($erro)): ?>
  <p class="aviso erro"><?= htmlspecialchars($erro) ?></p>
<?php endif; ?>

<form method="post" action="index.php?acao=login">
  <label>E-mail
    <input type="email" name="email" required autocomplete="username"
           value="<?= htmlspecialchars($email) ?>">
  </label>

  <label>Senha
    <input type="password" name="senha" required autocomplete="current-password">
  </label>

  <button type="submit" class="botao">Entrar</button>
</form>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
