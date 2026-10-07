// Versão 2 — o JavaScript apenas EXIBE o status recebido do backend.
const corpo = document.getElementById('corpo');
const mensagem = document.getElementById('mensagem');

fetch('api/alunos.php')
  .then(response => {
    if (!response.ok) throw new Error('HTTP ' + response.status);
    return response.json();
  })
  .then(alunos => {
    mensagem.textContent = '';

    alunos.forEach(aluno => {
      const tr = document.createElement('tr');

      const tdNome = document.createElement('td');
      tdNome.textContent = aluno.nome;

      const tdNota = document.createElement('td');
      tdNota.textContent = aluno.nota.toLocaleString('pt-BR', { minimumFractionDigits: 1 });

      const tdStatus = document.createElement('td');
      tdStatus.textContent = aluno.status;                 // sem cálculo aqui
      tdStatus.className = aluno.status.toLowerCase();

      tr.append(tdNome, tdNota, tdStatus);
      corpo.appendChild(tr);
    });
  })
  .catch(error => {
    console.error('Erro:', error);
    mensagem.textContent = 'Não foi possível carregar os alunos.';
  });
