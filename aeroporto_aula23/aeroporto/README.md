# Projeto Aeroporto - Aula 21 (Estrutura de sistemas)

PHP + MySQL, organizado em camadas (config, model, controller, view).

## Por que estruturar?
Quando cada arquivo mistura conexão, SQL, regras e HTML, mudar a senha do
banco exige editar vários arquivos, erros corrigidos num lugar continuam nos
outros e ninguém acha nada. Separando responsabilidades, cada arquivo faz uma
coisa só:

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| Config | `config/database.php` | Conexão PDO única (singleton) |
| Model | `models/Voo.php` | Todo o SQL de voos (listar, buscar, criar, editar, excluir) |
| Controller | `controllers/VooController.php` | Valida a entrada, chama o model, escolhe a view |
| View | `views/voos/*.php` | Só HTML com os dados recebidos |
| Includes | `includes/header.php`, `footer.php` | Cabeçalho/rodapé reutilizados |
| Entrada | `public/index.php` | Roteador (`?acao=listar/novo/salvar/editar/atualizar/excluir`) |

Fluxo: `Navegador -> public/index.php -> Controller -> Model -> MySQL`, e o
controller devolve uma View.

## Como rodar
1. Copie a pasta `aeroporto/` para o `htdocs` (XAMPP) ou `www` (WAMP).
2. Importe `database/aeroporto.sql` no MySQL. Se você já tem a tabela `voos`
   com dados, rode só:
   `ALTER TABLE voos MODIFY id INT NOT NULL AUTO_INCREMENT;`
3. Ajuste usuário/senha em `config/database.php`, se necessário.
4. Abra `http://localhost/aeroporto/public/index.php`.

## Checklist de entrega
- [x] Estrutura de pastas organizada
- [x] Conexão em um único arquivo (`config/database.php`)
- [x] Model `Voo` com listar, buscar, criar, editar e excluir
- [x] Todas as consultas com prepared statements
- [x] Nenhum SQL dentro das views
- [x] Saída de dados com `htmlspecialchars()`
- [x] Listar, criar, editar e excluir voos pelo navegador

## Observações
- A exclusão usa formulário POST (e não link GET), para que um link ou
  rastreador não consiga apagar registros.
- Erros do banco (trigger com `SIGNAL`, chave estrangeira) são capturados no
  controller e exibidos como aviso. Se você instalou os triggers da atividade
  anterior, por exemplo, tentar cadastrar um voo no portão `99` (em manutenção)
  mostra a mensagem do trigger no formulário.
- O model não lê `$_POST`; a validação fica no controller.

## Soft delete (atividade de backup e recuperação)
1. Rode `database/migration_soft_delete.sql` (coluna `deleted_at`, índice e tabela `auditoria`).
2. `Voo::excluir()` agora marca `deleted_at` e grava a auditoria na mesma transação; `Voo::restaurar()` desfaz.
3. A tela "Voos excluídos" (`?acao=excluidos`) lista e restaura.
4. Teste de rollback: `php tests/teste_rollback.php [id]`.
5. Explicações no `RELATORIO.md`.

## Aula 23 - SQL Injection
1. Rode `database/usuarios_teste.sql` (dados falsos).
2. Teste em `index.php?acao=buscar` (versão A vulnerável x versão B segura).
3. Preencha/confira `ENTREGA_SQL_INJECTION.md` e envie ao Moodle.
4. Depois da entrega, remova `Voo::buscarVulneravel()` e o ramo `versao=a`.
