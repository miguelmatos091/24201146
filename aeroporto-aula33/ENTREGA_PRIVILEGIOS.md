# Aula 24 - Privilégios no projeto do aeroporto

> **Atenção:** as saídas abaixo são as **esperadas** para o que está em
> `database/privilegios.sql` (não pude executar o MySQL aqui). Rode os comandos
> no seu computador e substitua cada resultado pelo que realmente aparecer
> (as mensagens exatas variam um pouco entre versões do MySQL).

> **Atualização (Aula 25):** o login passou a ler a tabela `usuarios`, então
> `database/privilegios.sql` ganhou `GRANT SELECT ON aeroporto.usuarios`. A
> saída de `SHOW GRANTS` abaixo é a da Aula 24 (com esse GRANT haveria uma
> linha a mais), e o `UNION` em `usuarios` só falha se a conta ainda não tiver
> esse SELECT. Por isso o método vulnerável `buscarVulneravel()` deve estar
> removido.

## Parte 1: SHOW GRANTS FOR 'app_aeroporto'@'localhost'

```
GRANT USAGE ON *.* TO `app_aeroporto`@`localhost`
GRANT SELECT, INSERT, UPDATE ON `aeroporto`.`voos` TO `app_aeroporto`@`localhost`
GRANT SELECT, INSERT ON `aeroporto`.`auditoria` TO `app_aeroporto`@`localhost`
```
Além do enunciado, concedi `SELECT, INSERT` em `auditoria`: a exclusão com
soft delete grava o log na mesma transação, e sem isso ela falharia.

## Parte 2: conexão
`config/database.php` agora usa `app_aeroporto` (a senha vem de `DB_PASS`).
O restante do código não mudou.

## Parte 3: teste do CRUD

| Operação | Esperado | O que aconteceu? |
|---|---|---|
| Listar voos (`SELECT`) | funciona | Funciona. |
| Criar voo (`INSERT`) | funciona | Funciona. |
| Editar voo (`UPDATE`) | funciona | Funciona. |
| Excluir voo (`DELETE`) | **erro** | **Pela tela funciona**, porque o projeto usa soft delete: é um `UPDATE` em `voos` mais um `INSERT` em `auditoria`, ambos permitidos. O `DELETE` de verdade, no terminal, é negado (abaixo). |

Mensagem do `DELETE` direto, no terminal com a conta nova:
```
ERROR 1142 (42000): DELETE command denied to user 'app_aeroporto'@'localhost' for table 'voos'
```
(`DROP TABLE voos` também é negado: `DROP command denied ...`.)

Anotação: como o "excluir" da tela é um `UPDATE`, quem impede apagar de
verdade é a conta sem `DELETE`, não o botão. O controller trata falhas de
permissão (códigos 1044/1142/1143) mostrando só "Operação não permitida." ao
usuário e gravando o detalhe com `error_log`.

## Parte 4: discussão

**1. O que mudou para a Maria? E para a conexão?**
Para a Maria, nada: o perfil de atendente dela na tabela `usuarios` é um
conceito da aplicação e continua o mesmo. Mudou para a conexão: antes, toda
requisição (de qualquer usuário do sistema) chegava ao banco como `root`, com
poder total; agora chega como `app_aeroporto`, que só lê, insere e atualiza
`voos` e lê/insere em `auditoria`.

**2. Quem decide se a Maria pode excluir um voo: o banco ou o código PHP?**
Os dois, em camadas diferentes. O PHP conhece a Maria e decide, pelo perfil
dela, se o botão aparece e se a ação é executada. O banco não conhece a Maria,
só a conta `app_aeroporto`, e define o limite máximo do que qualquer ação da
aplicação pode fazer. Com soft delete, o "excluir" é um `UPDATE`, então o
banco permite: a regra "Maria pode excluir?" fica por conta do código; o banco
só impede o `DELETE` físico.

**3. Com uma SQL Injection agora, o que o atacante ainda conseguiria? E com `root`?**
Com `app_aeroporto`, ele ainda poderia ler e alterar `voos` (por exemplo,
mudar status e horários de qualquer voo), inserir voos e ler ou inserir linhas
em `auditoria`. Não conseguiria apagar registros, derrubar tabelas, ler
`usuarios` (o `UNION` do payload 4 da Aula 23 falharia com erro 1142) nem
alterar o histórico de auditoria. Com `root`, conseguiria ler todos os bancos
do servidor, alterar e apagar qualquer dado, dar `DROP` no banco inteiro e
criar contas de administrador. Privilégios mínimos limitam o estrago, mas não
substituem prepared statements: a injeção ainda existiria.

## Desafio (adaptado ao meu esquema: `portao` no lugar do CPF)
1. `INSERT` em `voos` com a conta `relatorios`:
   `ERROR 1142 (42000): INSERT command denied to user 'relatorios'@'localhost' for table 'voos'`
3. `SELECT portao FROM voos;` depois de restringir as colunas:
   `ERROR 1143 (42000): SELECT command denied to user 'relatorios'@'localhost' for column 'portao' in table 'voos'`
4. A alternativa com view (`vw_voos_relatorio`) está em `database/privilegios.sql`.
