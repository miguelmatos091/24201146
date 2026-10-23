# Aula 23 - SQL Injection no sistema do Aeroporto

> **Atenção:** os resultados abaixo são o que se **espera** pela análise do SQL
> montado em cada versão. Rode os 4 payloads no seu projeto e confira/ajuste
> cada célula com o que você realmente viu antes de entregar.

## Como testar
1. Importe `database/usuarios_teste.sql` (tabela `usuarios` com dados falsos).
2. Abra `index.php?acao=buscar` e use o formulário (ele codifica a URL sozinho).
   Ou, direto na barra: `index.php?acao=buscar&versao=a&destino=...`
3. Adaptações ao meu esquema: a tabela `voos` não tem `origem`, então o
   `SELECT` usa 5 colunas: `id, numero_voo, destino, portao, status`. Como o
   controle `Lisboa` não existe nos dados, usei `Brasilia`. O `SELECT` também
   filtra `deleted_at IS NULL` (soft delete da atividade anterior).

## Comparação

| Payload | Versão A (sem prepared) | Versão B (com prepared) |
|---|---|---|
| 1 `Brasilia` | Lista os voos ativos com destino Brasilia (10 nos dados originais). | Idêntico: mesmo resultado. |
| 2 `'` | Erro de sintaxe SQL (1064) exibido na tela: a aspas extra quebrou a consulta e o erro vazou detalhes do banco. | Sem erro; busca o destino literal `'` e retorna 0 resultados. |
| 3 `' OR '1'='1` | Lista **todos** os voos ativos, ignorando o filtro de destino. | 0 resultados: procura um destino com esse texto exato. |
| 4 `x' UNION SELECT id, email, senha_hash, 4, 5 FROM usuarios -- ` | Mostra, nas colunas da tabela de voos, o id, e-mail e hash de senha de cada usuário (dados de outra tabela). | 0 resultados, nenhum dado vazado. |

Obs.: se o navegador remover o espaço final depois do `--`, use `-- -`.

## Perguntas

**1. Por que a versão B se comporta diferente com o mesmo texto de entrada?**
Na versão B a estrutura da consulta (`WHERE destino = :destino`) é definida
antes e o texto digitado é ligado ao placeholder como um valor. Aspas, `OR` e
`UNION` dentro desse valor são só caracteres comuns, nunca sintaxe. Na versão
A o texto é colado dentro da string SQL antes de enviar, então o que o usuário
digita altera a própria consulta.

**2. O que o banco recebe como comando e o que recebe como dado em cada versão?**
Na A, tudo é comando: o banco recebe uma única string SQL em que a parte
digitada pelo usuário já virou parte da sintaxe. Na B, o comando é só o
`SELECT ... WHERE destino = :destino` e o dado é o valor de `destino`, tratado
sempre como literal. (O PDO do MySQL, por padrão, emula o prepare e escapa o
valor no cliente; ainda é seguro, e `PDO::ATTR_EMULATE_PREPARES => false` faz
a separação ocorrer de fato no servidor.)

**3. Se só a versão A existisse em produção, qual seria o pior dano do payload 4?**
Vazamento de e-mails e hashes de senha de toda a tabela `usuarios` (e, com
variações do mesmo payload, de qualquer tabela que a conta do banco consiga
ler, inclusive a estrutura do banco). Com os hashes, o atacante tenta quebrar
as senhas offline, assume contas e testa as mesmas senhas em outros serviços.
Dependendo dos privilégios do usuário do banco, a mesma falha pode permitir
também alterar ou apagar dados; por isso a conta da aplicação deve ter o mínimo
de permissões (não usar `root`).

## Depois da entrega
Remova `buscarVulneravel()` do `models/Voo.php`, o ramo `versao === 'a'` do
`buscar()` no controller e a opção "A" do `<select>` em `views/voos/buscar.php`.
