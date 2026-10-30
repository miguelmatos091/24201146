<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Voos</h2>
<p><a class="botao" href="index.php?acao=novo">+ Novo voo</a></p>

<?php if (!$voos): ?>
  <p>Nenhum voo cadastrado.</p>
<?php else: ?>
<table>
  <tr>
    <th>Número</th><th>Destino</th><th>Portão</th>
    <th>Horário</th><th>Status</th><th>Ações</th>
  </tr>
  <?php foreach ($voos as $v): ?>
    <tr>
      <td><?= htmlspecialchars((string) $v['numero_voo']) ?></td>
      <td><?= htmlspecialchars($v['destino']) ?></td>
      <td><?= htmlspecialchars((string) $v['portao']) ?></td>
      <td><?= htmlspecialchars(substr($v['horario'], 0, 5)) ?></td>
      <td><?= htmlspecialchars($v['status']) ?></td>
      <td class="acoes">
        <a href="index.php?acao=editar&id=<?= (int) $v['id'] ?>">Editar</a>
        <?php if (ehAdmin()): ?>
        <form method="post" action="index.php?acao=excluir"
              onsubmit="return confirm('Excluir este voo?')">
          <input type="hidden" name="id" value="<?= (int) $v['id'] ?>">
          <button type="submit" class="perigo">Excluir</button>
        </form>
        <?php endif; ?>
      </td>
    </tr>
  <?php endforeach; ?>
</table>
<?php endif; ?>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
