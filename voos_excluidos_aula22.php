<?php if (!empty($_SESSION['flash'])): $f = $_SESSION['flash']; unset($_SESSION['flash']); ?>
  <p class="<?= htmlspecialchars($f['tipo']) ?>"><?= htmlspecialchars($f['msg']) ?></p>
<?php endif; ?>

<h1>Voos excluídos</h1>
<p><a href="index.php">Voltar aos voos</a></p>

<table border="1" cellpadding="6">
  <tr><th>Nº</th><th>Destino</th><th>Horário</th><th>Excluído em</th><th>Ações</th></tr>
  <?php foreach ($voos as $v): ?>
  <tr>
    <td><?= htmlspecialchars($v['numero_voo']) ?></td>
    <td><?= htmlspecialchars($v['destino']) ?></td>
    <td><?= htmlspecialchars($v['horario']) ?></td>
    <td><?= htmlspecialchars($v['deleted_at']) ?></td>
    <td>
      <form method="post" action="restaurar.php">
        <input type="hidden" name="id" value="<?= (int)$v['id'] ?>">
        <button type="submit">Restaurar</button>
      </form>
    </td>
  </tr>
  <?php endforeach; ?>
</table>
