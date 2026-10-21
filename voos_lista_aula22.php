<?php if (!empty($_SESSION['flash'])): $f = $_SESSION['flash']; unset($_SESSION['flash']); ?>
  <p class="<?= htmlspecialchars($f['tipo']) ?>"><?= htmlspecialchars($f['msg']) ?></p>
<?php endif; ?>

<h1>Voos</h1>
<p><a href="excluidos.php">Ver voos excluídos</a></p>

<table border="1" cellpadding="6">
  <tr><th>Nº</th><th>Destino</th><th>Portão</th><th>Horário</th><th>Status</th><th>Ações</th></tr>
  <?php foreach ($voos as $v): ?>
  <tr>
    <td><?= htmlspecialchars($v['numero_voo']) ?></td>
    <td><?= htmlspecialchars($v['destino']) ?></td>
    <td><?= htmlspecialchars($v['portao']) ?></td>
    <td><?= htmlspecialchars($v['horario']) ?></td>
    <td><?= htmlspecialchars($v['status']) ?></td>
    <td>
      <form method="post" action="excluir.php"
            onsubmit="return confirm('Excluir o voo <?= htmlspecialchars($v['numero_voo'], ENT_QUOTES) ?>?');">
        <input type="hidden" name="id" value="<?= (int)$v['id'] ?>">
        <button type="submit">Excluir</button>
      </form>
    </td>
  </tr>
  <?php endforeach; ?>
</table>
