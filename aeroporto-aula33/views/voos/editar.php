<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Editar voo</h2>

<form method="post" action="index.php?acao=atualizar&id=<?= (int) $voo['id'] ?>">
  <?php require __DIR__ . '/_form.php'; ?>
</form>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
