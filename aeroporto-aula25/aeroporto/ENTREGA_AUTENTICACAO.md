# Aula 25 - Login e validação no sistema do aeroporto

> Não consegui executar PHP/MySQL aqui: o código está escrito mas **não foi
> rodado**. Faça os testes abaixo no seu computador antes de entregar.

## Como configurar
1. Como root: `mysql -u root -p < database/usuarios.sql` (cria a tabela e os
   usuários de teste: `operador@aeroporto.com` e `admin@aeroporto.com`, senha
   `senha123`, gravada como hash).
2. Como root: `mysql -u root -p < database/privilegios.sql` (a conta
   `app_aeroporto` agora também tem `SELECT` em `usuarios`).
3. Abra `http://localhost/aeroporto/public/index.php`.

## Onde cada parte foi feita (adaptada ao MVC do projeto)
| Parte | Implementação |
|---|---|
| 1. Tabela | `database/usuarios.sql` (hash com `password_hash`) |
| 2. Login/logout | `AuthController` (`?acao=login`, `?acao=logout`), `models/Usuario.php` (prepared statement + `password_verify`), `views/auth/login.php`. Login chama `session_regenerate_id(true)`, grava `usuario_id`, `email` e `perfil` e a mensagem de erro é sempre `E-mail ou senha inválidos`. Logout limpa `$_SESSION`, apaga o cookie e chama `session_destroy()` (é um POST, botão "Sair") |
| 3. Proteger páginas | `includes/auth.php` (`exigirLogin()`), chamado em `public/index.php` antes de qualquer ação de voos (listar, criar, editar, excluir, excluídos, restaurar, buscar) |
| 4. Validação | `VooController::validar()` + erros em array `$erros`; só salva se estiver vazio e reexibe o formulário com a lista |
| 5. Erros do banco | PDO em `ERRMODE_EXCEPTION`; `try/catch (PDOException)` no controller (o model lança), `error_log` e mensagem `Não foi possível salvar o voo.`; um `catch (Throwable)` no `index.php` cobre falhas de conexão |
| Desafio | `excluir` só para `perfil = admin`; outros recebem **403** (`views/erro403.php`); o botão Excluir some para quem não é admin |

## Adaptações de validação (o esquema não tem os campos do exemplo)
A tabela `voos` não tem `codigo`, `origem` nem data de partida (só `horario`,
do tipo TIME), então as três regras do enunciado foram trocadas por regras
equivalentes sobre os campos que existem:
- `codigo` (2 letras + 3 ou 4 números) -> `numero_voo` com **3 ou 4 dígitos**;
- origem diferente de destino -> **número do voo único** entre os voos ativos
  (consulta com prepared statement) e **portão** com 1 ou 2 dígitos;
- data de partida no futuro -> não aplicável (sem coluna de data). Se o seu
  projeto tiver `data_partida`, basta comparar com `new DateTime()` no
  `validar()`.

## Critério de pronto (confira ao testar)
- [ ] Senhas gravadas como hash (veja `SELECT email, senha_hash FROM usuarios`)
- [ ] Login funciona; e-mail inexistente e senha errada mostram a mesma mensagem
- [ ] Abrir `index.php?acao=listar` sem login redireciona para o login
- [ ] "Sair" encerra a sessão (voltar à lista pede login de novo)
- [ ] Voo inválido (ex.: número `12`, portão `ABC`) é rejeitado com mensagem clara
- [ ] Teste da Parte 5: renomeie temporariamente a tabela `voos`; a tela mostra
      só `Não foi possível salvar o voo.` (ou a mensagem genérica) e o detalhe
      aparece no log do PHP/Apache
- [ ] Logado como `operador`, não há botão Excluir e um POST direto devolve 403;
      como `admin`, a exclusão funciona

## Efeitos nas atividades anteriores
- A auditoria do soft delete agora grava o `usuario_id` real da sessão.
- A busca da Aula 23 (versão A) mostra o erro bruto do banco e vai contra o
  critério de "nunca mostrar erro de banco". Ela só existe para o laboratório:
  remova `buscarVulneravel()` e o ramo `versao=a` depois da entrega.
