// Versão 1 — o JavaScript CALCULA o status.
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
      // Regra de negócio no frontend:
      const status = aluno.nota >= 7 ? 'Aprovado' : 'Reprovado';

      const tr = document.createElement('tr');

      const tdNome = document.createElement('td');
      tdNome.textContent = aluno.nome;            // textContent evita XSS

      const tdNota = document.createElement('td');
      tdNota.textContent = aluno.nota.toLocaleString('pt-BR', { minimumFractionDigits: 1 });

      const tdStatus = document.createElement('td');
      tdStatus.textContent = status;
      tdStatus.className = status.toLowerCase();

      tr.append(tdNome, tdNota, tdStatus);
      corpo.appendChild(tr);
    });
  })
  .catch(error => {
    console.error('Erro:', error);
    mensagem.textContent = 'Não foi possível carregar os alunos.';
  });
