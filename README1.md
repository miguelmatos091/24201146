# Atividade Prática 01 - Conceito de Dado e Informação: Sistema de Gerenciamento de Aeroporto

Este repositório contém a entrega da **Atividade Prática 01**, focada na análise inicial de requisitos, levantamento de dados, geração de informações e entrevista com o cliente para a concepção de um Sistema de Gerenciamento de Aeroporto.

---

## 1. Levantamento dos Dados

Para que o sistema opere de forma integrada, os dados brutos foram organizados nos 6 grupos a seguir:

### 👤 Dados dos Passageiros
* **Nome Completo:** Identificação civil do passageiro.
* **CPF / Passaporte:** Documento de identificação único (nacional ou internacional).
* **Data de Nascimento:** Cálculo de idade para tarifas/categorias (ex: menor desacompanhado).
* **Nacionalidade:** Controle de imigração e requisitos alfandegários.
* **E-mail e Telefone:** Meios de contato para notificações sobre o voo.
* **Necessidades Especiais:** Sinalização de mobilidade reduzida ou atendimento prioritário.

### 🛫 Dados dos Voos
* **Código do Voo:** Identificador único da rota (ex: AD4052).
* **Aeroporto de Origem e Destino:** Ponto de partida e chegada (códigos IATA/ICAO).
* **Data e Horário Previsto de Partida:** Horário agendado para decolagem.
* **Data e Horário Previsto de Chegada:** Horário agendado para pouso.
* **Status do Voo:** Situação em tempo real (Confirmado, Embarcando, Em Trânsito, Atrasado, Cancelado).
* **Portão de Embarque:** Terminal e portão designado para acesso à aeronave.
* **Pista de Decolagem/Pouso:** Pista atribuída pelo controle de tráfego aéreo local.

### ✈️ Dados das Aeronaves
* **Prefixos/Matrícula:** Código de registro da aeronave (ex: PR-GUO).
* **Modelo e Fabricante:** Especificação técnica (ex: Airbus A320, Boeing 737).
* **Capacidade Máxima de Passageiros:** Lotação máxima permitida.
* **Capacidade de Carga/Bagagem (kg):** Limite de peso para operação segura.
* **Status de Manutenção:** Indicador de prontidão operacional (Liberado, Em Manutenção).

### 🏢 Dados das Companhias Aéreas
* **Razão Social e Nome Fantasia:** Identificação jurídica e comercial da empresa.
* **Código IATA/ICAO:** Sigla internacional de representação (ex: AZU / AD).
* **CNPJ:** Registro fiscal da empresa.
* **Guichês de Check-in Atribuídos:** Faixa de guichês alocados no terminal.

### 🧳 Dados das Bagagens
* **Código de Etiqueta (Tag ID):** Código de barras único impresso no despacho.
* **Peso (kg):** Medição para controle de franquia e balanço da aeronave.
* **Voo Associado:** Voo em que a bagagem será transportada.
* **Passageiro Proprietário:** Vínculo com o bilhete do passageiro.
* **Status do Rastreio:** Localização no fluxo (Despachada, Em Trânsito, Carregada, Restituída).

### 👨‍✈️ Dados dos Funcionários
* **Matrícula:** Registro funcional no sistema do aeroporto.
* **Nome Completo:** Identificação do colaborador.
* **Cargo / Função:** Papel desempenhado (Agente de Pátio, Operador de Guichê, Agente de Segurança).
* **Turno de Trabalho:** Horário de início e fim da jornada.
* **Credencial de Acesso:** Nível de permissão para áreas restritas do terminal.

---

## 2. Informações Fornecidas pelo Sistema

A partir do processamento e cruzamento dos dados brutos organizados acima, o sistema será capaz de gerar as seguintes **informações**:

1. **Painel de Próximas Decolagens do Dia:** Lista cronológica dos voos partindo nas próximas horas.
2. **Relatório de Voos Atrasados ou Cancelados:** Mapeamento de inconsistências na malha aérea e impacto de tempo.
3. **Manifesto de Passageiros por Voo (Pax List):** Relação completa de pessoas a bordo de uma aeronave específica.
4. **Histórico de Viagens do Passageiro:** Registro consolidado de todos os voos já realizados por um cliente.
5. **Carga Total de Bagagem por Voo:** Soma do peso total de bagagens despachadas para balanceamento de carga.
6. **Localização de Portões e Guichês Ativos:** Exibição em tempo real de onde cada voo está embarcando.
7. **Taxa de Ocupação da Aeronave:** Percentual de assentos vendidos em relação à capacidade máxima.
8. **Tempo Médio de Permanência em Pista:** Indicador de eficiência do tráfego em solo entre pouso e acoplamento.
9. **Relatório de Bagagens Extraviadas ou Retidas:** Lista de etiquetas sem confirmação de embarque/restituição.
10. **Alocação de Equipe por Turno:** Mapeamento de funcionários em serviço por setor do aeroporto.
11. **Volume Diário de Passageiros no Terminal:** Total de pessoas em trânsito (embarques + desembarques).
12. **Aeronaves Atualmente em Manutenção:** Relação de aviões indisponíveis para operação comercial.
13. **Faturamento Estimado por Companhia Aérea:** Projeção baseada em taxas de pouso/decolagem e uso de infraestrutura.
14. **Passageiros com Necessidade de Atendimento Especial por Voo:** Relação para apoio prévio de solo e bordo.
15. **Tempo Médio de Espera na Restituição de Bagagens:** Métrica do desembarque até a esteira para avaliação de SLA.

---

## 3. Dados Indispensáveis

| # | Dado | Justificativa |
|---|---|---|
| 1 | **Código do Voo** | É a chave central de identificação da operação; sem ele é impossível vincular passageiros, bagagens e horários. |
| 2 | **CPF / Passaporte do Passageiro** | Essencial para autenticação jurídica, controle de segurança e exigências de órgãos governamentais (PF/ANAC). |
| 3 | **Código de Etiqueta da Bagagem** | Garante o Rastreamento individual do pertence, evitando extravios e garantindo associação correta ao voo. |
| 4 | **Matrícula/Prefixo da Aeronave** | Imprescindível para validar se a aeronave possui capacidade e homologação para cumprir a rota designada. |
| 5 | **Status do Voo** | Informação crítica de operação em tempo real para orientar passageiros e equipes de solo sobre alterações. |
| 6 | **Portão de Embarque** | Direciona o fluxo físico dos passageiros no terminal, evitando perdas de voo e aglomerações indevidas. |
| 7 | **Horário Previsto de Partida** | Serve como base estrutural para a montagem de toda a malha operacional e alocação de recursos do aeroporto. |
| 8 | **Capacidade Máxima da Aeronave** | Limite físico que impede a venda em overbooking e garante os parâmetros de segurança de voo. |
| 9 | **Peso da Bagagem** | Necessário para o cálculo de peso/balanço (Weight and Balance) da aeronave antes da decolagem. |
| 10 | **Credencial do Funcionário** | Garante a segurança física do aeroporto ao restringir o acesso a áreas operacionais críticas. |

---

## 4. Perguntas para o Cliente (Levantamento de Requisitos)

1. Como é realizado o processo de integração entre o sistema do aeroporto e os sistemas próprios de cada companhia aérea?
2. Existe algum fluxo automatizado para realocação de portões caso um voo atrase mais do que o tempo limite previsto?
3. Como o aeroporto gerencia o limite de capacidade física do pátio de aeronaves durante horários de pico?
4. Qual é a regra de negócio aplicada para o despacho e triagem de bagagens em conexões internacionais?
5. Como o sistema deve tratar alertas de segurança (ex: passageiro que faz check-in mas não embarca no portão)?
6. O sistema deve emitir notificações diretas aos passageiros (App/SMS/Painéis) ou apenas atualizar a base de dados central?
7. De que forma é controlado o tempo de permanência de aeronaves nos *fingers* (pontes de embarque) e a cobrança dessa utilização?
8. Quais órgãos reguladores (ex: ANAC, Polícia Federal, Receita Federal) precisam ter acesso direto aos relatórios do sistema?
9. Como funciona o protocolo do aeroporto em situações imprevisíveis de fechamento de pista por mau tempo?
10. Existe integração com os sistemas de estacionamento e transportes terrestres conectados ao terminal?

---

## 5. Reflexão

### Qual foi a maior dificuldade encontrada durante a atividade?
A maior dificuldade foi abstrair a complexidade de um ambiente real e dinâmico como um aeroporto para separar claramente o que são **dados brutos** (registros isolados) do que são **informações** (dados processados e com significado). Além disso, entender as interdependências entre os módulos — como a relação entre peso de bagagem, capacidade da aeronave e segurança de voo — exigiu uma visão sistêmica detalhada.

### Você acredita que seja possível desenvolver um sistema sem realizar esse levantamento inicial? Justifique sua resposta.
**Não, não é possível.** Desenvolver um sistema sem o levantamento prévio de dados e informações equivale a construir uma casa sem planta estrutural. Sem essa etapa, corre-se o risco de:
* Omitir dados críticos para o funcionamento do negócio;
* Criar estruturas de armazenamento inadequadas;
* Entregar um software que não atende às reais necessidades operacionais do cliente, gerando retrabalho custoso e possíveis falhas de segurança no ambiente aeroportuário.
