# Sistema Acadêmico — Relacionamento de Entidades com Arquivos

Sistema em Python que gerencia **alunos** e **notas** usando apenas arquivos de
texto (`alunos.txt` e `notas.txt`) — sem banco de dados. O relacionamento entre
as duas entidades é feito pelo campo `ID_ALUNO`.

## Estrutura do projeto

```
sistema-academico/
├── sistema.py      # código do sistema (menu + todas as funções)
├── alunos.txt       # dados dos alunos (ID;NOME;TELEFONE;EMAIL)
├── notas.txt         # dados das notas (ID_ALUNO;DISCIPLINA;NOTA)
└── README.md
```

## Como executar

Requer apenas Python 3 instalado (sem bibliotecas externas).

```bash
python3 sistema.py
```

Um menu interativo será exibido no terminal:

```
1 - Cadastrar aluno
2 - Listar alunos
3 - Buscar aluno
4 - Cadastrar nota
5 - Consultar nota
6 - Listar todas as notas de um aluno
7 - Calcular média de um aluno
8 - Editar uma nota
0 - Sair
```

## Funcionalidades implementadas

**Obrigatórias**
- Cadastrar aluno (com verificação de ID duplicado)
- Listar alunos
- Buscar aluno pelo nome
- Cadastrar nota (verifica se o aluno existe antes de gravar)
- Consultar nota de um aluno em uma disciplina específica

**Desafios extras implementados (1, 2 e 3)**
1. **Listar todas as notas de um aluno** — opção 6 do menu.
2. **Calcular a média de um aluno** — opção 7 do menu.
3. **Editar uma nota** — opção 8 do menu.

Os demais desafios (excluir nota, buscar por disciplina, buscar por nota
mínima etc.) não foram implementados nesta versão, mas seguem o mesmo padrão
das funções já existentes — basta adicionar uma nova função e uma nova opção
no dicionário `opcoes` dentro de `menu()`.

## Como os dados persistem

Cada função de cadastro/edição:
1. Carrega o arquivo inteiro para a memória (`carregar_alunos` / `carregar_notas`);
2. Faz a alteração na lista em memória;
3. Regrava o arquivo inteiro (`salvar_alunos` / `salvar_notas`).

Assim, os dados continuam existindo mesmo depois de fechar o programa.

---

## Reflexão

**Como o programa consegue identificar a qual aluno uma determinada nota pertence?**
Cada linha de `notas.txt` começa com o campo `ID_ALUNO`. Quando o programa
precisa saber as notas de alguém, ele primeiro localiza o aluno em
`alunos.txt` pelo nome e descobre o seu `ID`. Depois, percorre `notas.txt`
comparando esse mesmo `ID` com o campo `ID_ALUNO` de cada linha. As linhas
que possuem o mesmo ID pertencem a esse aluno — é esse valor compartilhado
entre os dois arquivos que faz o relacionamento existir.

**Por que utilizamos um identificador único?**
Porque é o único campo que garante que cada aluno seja distinguido de forma
inequívoca, mesmo que outros dados se repitam ou mudem (como telefone,
e-mail ou até o nome, em caso de homônimos).

**O que aconteceria se utilizássemos apenas o nome do aluno?**
Dois alunos com o mesmo nome (ou o mesmo aluno com o nome digitado de forma
levemente diferente) fariam o sistema misturar ou perder notas, já que a
busca não teria como diferenciar um "João Silva" do outro. Além disso,
qualquer erro de digitação ou alteração de nome quebraria o vínculo com as
notas já cadastradas.

**Como garantir que uma nota pertença a um aluno existente?**
Validando, antes de gravar qualquer nota, se o `ID` informado (ou o nome
buscado) realmente existe em `alunos.txt`. É exatamente o que a função
`cadastrar_nota()` faz: ela busca o aluno primeiro e só grava a nota se o
aluno for encontrado.

**Quais dificuldades aparecem quando as informações estão distribuídas em diferentes arquivos?**
- É preciso reescrever o arquivo inteiro a cada alteração, pois arquivos de
  texto simples não permitem editar uma linha "no meio" com facilidade;
- Não existe integridade referencial automática (como em um banco de
  dados) — o próprio programa precisa garantir manualmente que uma nota
  nunca aponte para um ID de aluno inexistente;
- Buscas ficam mais lentas à medida que os arquivos crescem, pois é preciso
  ler tudo sequencialmente (não há índices);
- Erros de formatação em uma linha (um `;` a mais ou a menos) podem quebrar
  a leitura de todo o arquivo.

---

## Publicando no GitHub

Passo a passo para subir este projeto:

```bash
# 1. Entre na pasta do projeto
cd sistema-academico

# 2. Inicialize o repositório git local
git init

# 3. Adicione todos os arquivos
git add .

# 4. Faça o primeiro commit
git commit -m "Sistema acadêmico com arquivos - alunos e notas"

# 5. Crie um repositório vazio no GitHub (pelo site github.com,
#    botão "New repository"), sem README/gitignore/license.

# 6. Conecte o repositório local ao remoto (troque SEU-USUARIO e NOME-DO-REPO)
git remote add origin https://github.com/SEU-USUARIO/NOME-DO-REPO.git

# 7. Envie o código
git branch -M main
git push -u origin main
```

Depois disso, o repositório estará disponível em
`https://github.com/SEU-USUARIO/NOME-DO-REPO`.

### Dica: `.gitignore`
Se quiser versionar apenas o código-fonte e não os dados de teste, crie um
arquivo `.gitignore` com:
```
alunos.txt
notas.txt
```
Assim cada pessoa que clonar o projeto começa com arquivos vazios (o
programa já cria os arquivos automaticamente se eles não existirem).
