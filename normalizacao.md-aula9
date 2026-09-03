# Normalização do Banco de Dados — `aeroporto`

## 1. Banco de dados utilizado

O grupo utilizou o banco **aeroporto**, desenvolvido desde o início do semestre. O ponto de
partida da análise é o arquivo `sql_aula_8.sql`, produzido na Aula 8, contendo uma única
tabela (`voos`) com 30 registros.

```sql
CREATE TABLE voos (
    id INT PRIMARY KEY,
    numero_voo INT NOT NULL,
    destino VARCHAR(100) NOT NULL,
    portao VARCHAR(10),
    horario TIME NOT NULL,
    status VARCHAR(20) NOT NULL
);
```

---

## 2. Comparação com o SQL da Aula 8

| Aspecto | SQL da Aula 8 | Estrutura atual (após análise) |
|---|---|---|
| Tabelas | 1 (`voos`) | 2 (`voos`, `destinos`) |
| Chave primária | `voos.id` | `voos.id` e `destinos.id_destino` |
| Chave estrangeira | Nenhuma | `voos.id_destino → destinos.id_destino` |
| Atributos de `voos` | id, numero_voo, destino, portao, horario, status | id, numero_voo, id_destino, portao, horario, status |
| Redundância | `destino` repetido em texto livre (ex.: "Brasilia" aparece em 10 das 30 linhas) | Texto do destino armazenado uma única vez, referenciado por chave |
| Restrição de unicidade | `numero_voo` sem `UNIQUE` | `numero_voo UNIQUE` (reforça a regra de negócio) |

**Levantamento quantitativo feito sobre os dados da Aula 8:**
- `destino` se repete com o mesmo texto em várias linhas: Brasília (10x), Rio de Janeiro (4x),
  São Paulo (4x), Salvador (3x), Recife (3x), Belo Horizonte (2x), Curitiba (2x), Fortaleza (1x),
  Porto Alegre (1x).
- `numero_voo` não se repete no recorte de dados (30 valores distintos para 30 linhas), mas
  **não havia nenhuma restrição `UNIQUE`** garantindo isso no schema da Aula 8.
- `portao` se repete entre voos diferentes, o que é esperado (o mesmo portão físico é usado por
  voos distintos em horários diferentes) e **não** representa um problema de normalização.

O arquivo original foi preservado sem alterações em `sql_aula_8.sql`, para permitir esta
comparação.

---

## 3. Aplicação das Formas Normais

```text
SQL da Aula 8
      ↓
     1FN  → sem violações
      ↓
     2FN  → sem violações
      ↓
     3FN  → violação encontrada e corrigida
      ↓
     4FN  → sem violações (após a correção da 3FN)
      ↓
     5FN  → sem violações
      ↓
Modelo final normalizado
```

### 3.1 Primeira Forma Normal (1FN)

**Critério:** todos os atributos devem conter valores atômicos (indivisíveis) e não pode haver
grupos repetitivos ou atributos multivalorados.

**Análise:** todos os atributos de `voos` (`id`, `numero_voo`, `destino`, `portao`, `horario`,
`status`) armazenam um único valor atômico por linha. Não há listas, campos concatenados nem
grupos repetitivos (por exemplo, não há uma coluna do tipo "portoes" com múltiplos valores
separados por vírgula).

**Conclusão:** a tabela já satisfaz a 1FN. **Nenhuma alteração foi necessária.**

### 3.2 Segunda Forma Normal (2FN)

**Critério:** a tabela deve estar na 1FN e todo atributo não-chave deve depender
**integralmente** da chave primária (não pode haver dependência parcial em relação a apenas
parte de uma chave composta).

**Análise:** a chave primária de `voos` é `id`, um atributo único e não composto. Dependência
parcial só pode existir quando a chave primária é composta por dois ou mais atributos — o que
não é o caso aqui. Logo, por definição, não há como ocorrer violação de 2FN nesta tabela.

**Conclusão:** a tabela já satisfaz a 2FN. **Nenhuma alteração foi necessária.**

### 3.3 Terceira Forma Normal (3FN) — violação encontrada

**Critério:** a tabela deve estar na 2FN e não pode haver dependência **transitiva**, ou seja,
um atributo não-chave não pode depender de outro atributo não-chave — todo atributo não-chave
deve depender **diretamente** da chave primária.

**Dependências funcionais identificadas:**

- `id → numero_voo, destino, portao, horario, status` (dependência direta da chave, trivial).
- `numero_voo → destino` — regra de negócio do domínio: o **número do voo é atribuído pela
  companhia aérea a uma rota específica** e não muda entre operações desse voo (é assim que
  funciona um número de voo real, ex.: o voo "305" sempre liga a mesma origem ao mesmo destino).

Como `numero_voo` não possuía restrição `UNIQUE` no SQL da Aula 8 (ou seja, não era garantido
como chave candidata), a dependência `numero_voo → destino` caracteriza uma **dependência
transitiva**:

```
id → numero_voo → destino
```

Isso significa que `destino` (atributo não-chave) depende de `numero_voo` (outro atributo
não-chave), e não diretamente da chave primária `id`. Essa é a definição clássica de violação
da 3FN.

**Evidência prática dessa violação:** a redundância observada nos dados (o texto "Brasilia"
repetido em 10 linhas) é consequência direta dessa dependência transitiva — qualquer alteração
no nome de uma cidade exigiria atualizar múltiplas linhas, criando risco de inconsistência
(anomalia de atualização).

**Correção aplicada:** decomposição da tabela `voos` em duas tabelas, eliminando a dependência
transitiva:

```sql
CREATE TABLE destinos (
    id_destino INT PRIMARY KEY,
    cidade VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE voos (
    id INT PRIMARY KEY,
    numero_voo INT NOT NULL UNIQUE,
    id_destino INT NOT NULL,
    portao VARCHAR(10),
    horario TIME NOT NULL,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_voos_destino FOREIGN KEY (id_destino)
        REFERENCES destinos (id_destino)
);
```

Com isso:
- `destino` passa a depender diretamente da chave de `destinos` (`id_destino`), e não mais
  transitivamente de `numero_voo` dentro de `voos`.
- A restrição `UNIQUE` foi adicionada a `numero_voo`, tornando explícita no schema a regra de
  negócio "um número de voo identifica uma única rota", o que também é uma boa prática de
  integridade referencial.
- `portao`, `horario` e `status` permanecem em `voos`, pois dependem diretamente de `id` (o
  portão e o horário são atributos da **operação específica** daquele voo naquele dia, não da
  rota em si) e não têm dependência transitiva demonstrável a partir de nenhum outro atributo
  não-chave.

**Conclusão:** havia violação da 3FN. **Alteração necessária e realizada** (extração da tabela
`destinos`).

### 3.4 Quarta Forma Normal (4FN)

**Critério:** a tabela deve estar na 3FN (ou BCNF) e não pode haver **dependências
multivaloradas** não triviais — isto é, duas ou mais informações independentes e multivaloradas
sobre a mesma entidade não podem estar combinadas na mesma tabela (o exemplo clássico é uma
tabela que cruza "idiomas falados" com "certificações" de um funcionário, gerando linhas para
todas as combinações).

**Análise:** nas tabelas finais (`voos` e `destinos`), cada atributo representa um único fato
sobre a entidade correspondente:
- `voos` descreve uma única operação de voo (um número de voo, um portão, um horário, um status).
- `destinos` descreve uma única cidade.

Não existem dois atributos multivalorados independentes combinados em uma mesma tabela que
gerem produto cartesiano de combinações.

**Conclusão:** não há violação de 4FN. **Nenhuma alteração foi necessária**, além da já
realizada na 3FN (que, ao eliminar a dependência transitiva, também já eliminou o único ponto
de risco de dependência multivalorada indireta ligado a `destino`).

### 3.5 Quinta Forma Normal (5FN)

**Critério:** a tabela deve estar na 4FN e não pode haver **dependência de junção** (join
dependency) não implícita pelas chaves candidatas — ou seja, a tabela não pode ser decomposta
em três ou mais tabelas que, ao serem reunidas via `JOIN`, gerem linhas espúrias, algo comum em
relacionamentos ternários (ex.: fornecedor–peça–projeto).

**Análise:** o modelo final possui apenas um relacionamento binário simples (1:N) entre
`destinos` e `voos`, representado por uma chave estrangeira direta. Não há relação ternária ou
de ordem superior no domínio modelado (não existem, por exemplo, combinações do tipo
voo–aeronave–tripulação que exigissem uma tabela associativa própria).

**Conclusão:** não há violação de 5FN. **Nenhuma alteração foi necessária.**

---

## 4. Modelo final normalizado

```text
destinos
├── id_destino (PK)
└── cidade (UNIQUE)

voos
├── id (PK)
├── numero_voo (UNIQUE)
├── id_destino (FK → destinos.id_destino)
├── portao
├── horario
└── status
```

**Resumo das alterações realizadas:**

| Forma Normal | Violação? | Ação |
|---|---|---|
| 1FN | Não | Nenhuma alteração |
| 2FN | Não | Nenhuma alteração |
| 3FN | **Sim** | Extração da tabela `destinos`; `voos.destino` substituído por `voos.id_destino` (FK); `numero_voo` passou a ser `UNIQUE` |
| 4FN | Não | Nenhuma alteração adicional |
| 5FN | Não | Nenhuma alteração |

O modelo final elimina a dependência transitiva `id → numero_voo → destino`, remove a
redundância de texto (o nome de cada cidade agora é armazenado uma única vez) e reforça, via
`UNIQUE`, a regra de negócio de que cada número de voo corresponde a uma única rota — sem
introduzir tabelas desnecessárias, conforme orientado na atividade.

O SQL correspondente a este modelo está em `sql_normalizado.sql`.
