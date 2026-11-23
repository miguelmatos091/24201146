<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Voos excluídos</h2>
<p><a href="index.php?acao=listar">&larr; Voltar para os voos</a></p>

<?php if (!$voos): ?>
  <p>Nenhum voo excluído.</p>
<?php else: ?>
<table>
  <tr>
    <th>Número</th><th>Destino</th><th>Portão</th>
    <th>Horário</th><th>Status</th><th>Excluído em</th><th>Ações</th>
  </tr>
  <?php foreach ($voos as $v): ?>
    <tr>
      <td><?= htmlspecialchars((string) $v['numero_voo']) ?></td>
      <td><?= htmlspecialchars($v['destino']) ?></td>
      <td><?= htmlspecialchars((string) $v['portao']) ?></td>
      <td><?= htmlspecialchars(substr($v['horario'], 0, 5)) ?></td>
      <td><?= htmlspecialchars($v['status']) ?></td>
      <td><?= htmlspecialchars($v['deleted_at']) ?></td>
      <td class="acoes">
        <form method="post" action="index.php?acao=restaurar"
              onsubmit="return confirm('Restaurar este voo?')">
          <input type="hidden" name="id" value="<?= (int) $v['id'] ?>">
          <button type="submit">Restaurar</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
</table>
<?php endif; ?>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
