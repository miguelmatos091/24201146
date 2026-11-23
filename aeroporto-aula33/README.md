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

## Aula 24 - Privilégios
1. Rode `database/privilegios.sql` como root (troque a senha de `app_aeroporto`).
2. `config/database.php` usa `app_aeroporto`; defina `DB_PASS` com a sua senha.
3. Migrations e scripts de estrutura (ALTER/CREATE) continuam sendo rodados como root.
4. Entrega: `ENTREGA_PRIVILEGIOS.md` (confira as saídas no seu MySQL).

## Aula 25 - Login e validação
1. Rode `database/usuarios.sql` e `database/privilegios.sql` como root.
2. Entre com `admin@aeroporto.com` ou `operador@aeroporto.com` (senha `senha123`) e troque essas senhas fora do laboratório.
3. Detalhes e roteiro de testes em `ENTREGA_AUTENTICACAO.md`.

## Aula 30 - Migrations (expandir e contrair)
Arquivos: `migrate.php`, `migrations/001..004`, `backfill_destino.php`,
`config/conexao_migracao.php`, `respostas.md`, `schema_migrations.txt`.

Adaptação: `voos` não tem `origem`, então o exemplo foi feito com
`destino` -> `aeroporto_destino` (ver `respostas.md`).

Roteiro (no terminal, dentro da pasta do projeto; **nunca no banco do projeto**):
```bash
# 0) cópia do banco
mysqldump -u root -p aeroporto > aeroporto_backup.sql
mysql -u root -p -e "CREATE DATABASE aeroporto_lab CHARACTER SET utf8mb4"
mysql -u root -p aeroporto_lab < aeroporto_backup.sql

# 1) runner (use MIGRATE_DB_PASS se o root tiver senha)
php migrate.php up              # aplica 001 ... e confira SELECT * FROM schema_migrations
# Parte 2: DESCRIBE voos; php migrate.php down; DESCRIBE voos; php migrate.php up
# Parte 3: aplique até a 003, rode o backfill e confira:
php backfill_destino.php
#   SELECT COUNT(*) FROM voos WHERE aeroporto_destino IS NULL;   -- deve ser 0
# Passo 3 (código) e Passo 4:
php migrate.php up              # aplica a 004
php migrate.php down            # Pergunta 2: a coluna volta, os dados não
php migrate.php up
```
Dica: como `up` aplica todas as pendentes de uma vez, para parar na 003 mova
temporariamente `004_drop_destino.sql` para fora da pasta `migrations/`.

Para testar a aplicação (estado final do código) no banco de cópia:
```sql
-- como root
GRANT SELECT, INSERT, UPDATE ON aeroporto_lab.voos TO 'app_aeroporto'@'localhost';
GRANT SELECT, INSERT ON aeroporto_lab.auditoria TO 'app_aeroporto'@'localhost';
GRANT SELECT ON aeroporto_lab.usuarios TO 'app_aeroporto'@'localhost';
```
e inicie o servidor com `DB_NAME=aeroporto_lab` e `DB_PASS` definidos.
A conta da aplicação não tem `ALTER`: as migrations rodam como administrador.

## Painéis do Aeroporto (modelo dimensional)
`database/dw_aeroporto.sql` (estrela, ETL e consultas) e `ENTREGA_PAINEIS.md` (fichas, lacunas, ETL, wireframe).
