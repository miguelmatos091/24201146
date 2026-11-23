<?php
/**
 * Campos do formulário, compartilhados por criar.php e editar.php.
 * Espera: $voo (array com os valores atuais) e $erros (array de mensagens).
 */
?>
<?php if (!empty($erros)): ?>
  <ul class="aviso erro">
    <?php foreach ($erros as $erro): ?>
      <li><?= htmlspecialchars($erro) ?></li>
    <?php endforeach; ?>
  </ul>
<?php endif; ?>

<label>Número do voo
  <input type="number" name="numero_voo" min="1" required
         value="<?= htmlspecialchars((string) $voo['numero_voo']) ?>">
</label>

<label>Destino
  <input type="text" name="destino" maxlength="100" required
         value="<?= htmlspecialchars($voo['destino']) ?>">
</label>

<label>Portão
  <input type="text" name="portao" maxlength="10"
         value="<?= htmlspecialchars((string) $voo['portao']) ?>">
</label>

<label>Horário
  <input type="time" name="horario" required
         value="<?= htmlspecialchars(substr((string) $voo['horario'], 0, 5)) ?>">
</label>

<label>Status
  <select name="status" required>
    <?php foreach (Voo::STATUS_VALIDOS as $s): ?>
      <option value="<?= htmlspecialchars($s) ?>"
        <?= $voo['status'] === $s ? 'selected' : '' ?>>
        <?= htmlspecialchars($s) ?>
      </option>
    <?php endforeach; ?>
  </select>
</label>

<p>
  <button type="submit" class="botao">Salvar</button>
  <a href="index.php?acao=listar">Cancelar</a>
</p>
