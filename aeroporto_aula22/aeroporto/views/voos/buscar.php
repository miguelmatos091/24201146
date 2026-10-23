<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Buscar voos por destino</h2>

<form method="get" action="index.php">
  <input type="hidden" name="acao" value="buscar">
  <label>Versão
    <select name="versao">
      <option value="b" <?= ($versao ?? 'b') === 'b' ? 'selected' : '' ?>>B - com prepared statements (segura)</option>
      <option value="a" <?= ($versao ?? 'b') === 'a' ? 'selected' : '' ?>>A - sem prepared statements (vulnerável)</option>
    </select>
  </label>
  <label>Destino
    <input type="text" name="destino" value="<?= htmlspecialchars($destino ?? '') ?>">
  </label>
  <button type="submit" class="botao">Buscar</button>
</form>

<?php if (!empty($erroSql)): ?>
  <pre class="aviso erro"><?= htmlspecialchars($erroSql) ?></pre>
<?php elseif (isset($_GET['destino'])): ?>
  <p><?= count($voos) ?> resultado(s).</p>
  <?php if ($voos): ?>
  <table>
    <tr><th>ID</th><th>Número</th><th>Destino</th><th>Portão</th><th>Status</th></tr>
    <?php foreach ($voos as $v): ?>
      <tr>
        <td><?= htmlspecialchars((string) $v['id']) ?></td>
        <td><?= htmlspecialchars((string) $v['numero_voo']) ?></td>
        <td><?= htmlspecialchars((string) $v['destino']) ?></td>
        <td><?= htmlspecialchars((string) $v['portao']) ?></td>
        <td><?= htmlspecialchars((string) $v['status']) ?></td>
      </tr>
    <?php endforeach; ?>
  </table>
  <?php endif; ?>
<?php endif; ?>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
