# Respostas — Alunos, Notas e Status

## 8. Comparação das abordagens

| Aspecto | Regra no JavaScript | Regra no PHP |
|---|---|---|
| Quem decide o status | Navegador | Servidor |
| JSON | `{id, nome, nota}` | `{id, nome, nota, status}` |
| Segurança | Código visível e alterável (F12) | Código fora do alcance do usuário |
| Reutilização | Cada cliente reimplementa a regra | Todos os clientes recebem o resultado pronto |
| Consistência | Risco de regras diferentes em cada cliente | Fonte única da verdade |
| Manutenção | Alterar a média exige mexer em todos os clientes | Altera-se em um único lugar |

## 9. Onde a regra de negócio deve ficar?

**No backend (PHP).** O frontend deve cuidar da apresentação e da interação; o backend, das regras, da validação e do acesso aos dados.

- **Segurança:** o JavaScript roda no navegador, e o usuário pode ler e modificar qualquer coisa nele (DevTools, requisições forjadas). Uma regra apenas no frontend pode ser contornada. O frontend nunca é confiável; o servidor é o ponto onde a regra realmente vale.
- **Reutilização:** a mesma regra pode ser exigida por um app mobile, um relatório, outro sistema. No backend ela é escrita uma vez; no frontend teria de ser copiada em cada cliente.
- **Consistência dos dados:** com a regra espalhada, a web pode mostrar "Aprovado" para 6,9 (arredondando) enquanto o app mostra "Reprovado". Uma única implementação garante que todos vejam o mesmo resultado.
- **Manutenção:** se a média passar de 7 para 6, basta alterar uma constante no PHP. Com a regra no JS, seria preciso corrigir e republicar cada cliente, e quem estiver com a versão antiga em cache continuaria vendo o resultado errado.
- **Vários clientes consumindo a mesma API:** a API é o contrato entre as camadas. Quando ela já entrega o status, qualquer cliente (web, mobile, terceiros) funciona sem conhecer a regra.
- **Responsabilidade de cada camada:** frontend = interface e interação (não guarda segredo, não decide regra); backend = regras, validação e acesso ao banco; banco = armazenamento e integridade (PK, FK, constraints, como o `CHECK` da nota).

**Ressalva:** no frontend cabe lógica de apresentação (formatar a nota como "8,5", colorir o status, ordenar a tabela). Validações de formulário no JS são úteis para a experiência do usuário, mas devem ser repetidas no servidor.

## Como executar

1. Rode `banco/alunos.sql` (phpMyAdmin, DBeaver ou MySQL Workbench) e crie o usuário `app_escola` com os dados de `config.php`.
2. Coloque a pasta `atividade/` no servidor (XAMPP/Laragon: `htdocs`, ou Docker Compose com php-apache).
3. Abra `http://localhost/atividade/versao1-js/` e `http://localhost/atividade/versao2-php/`.
4. Teste o JSON direto em `.../api/alunos.php` antes de depurar o frontend.
