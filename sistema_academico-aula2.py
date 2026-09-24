"""
Sistema Acadêmico — Alunos e Notas em Arquivos
================================================
Armazena alunos em 'alunos.txt' e notas em 'notas.txt'.
Nenhum banco de dados é utilizado: tudo é lido e gravado em arquivos texto.

Formato dos arquivos:
    alunos.txt -> ID;NOME;TELEFONE;EMAIL
    notas.txt  -> ID_ALUNO;DISCIPLINA;NOTA
"""

import os

ARQUIVO_ALUNOS = "alunos.txt"
ARQUIVO_NOTAS = "notas.txt"


# ---------------------------------------------------------------------------
# FUNÇÕES DE APOIO — LEITURA E ESCRITA DOS ARQUIVOS
# ---------------------------------------------------------------------------

def ler_alunos():
    """Lê o arquivo de alunos e retorna uma lista de dicionários."""
    alunos = []
    if not os.path.exists(ARQUIVO_ALUNOS):
        return alunos

    with open(ARQUIVO_ALUNOS, "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if not linha:
                continue
            partes = linha.split(";")
            if len(partes) != 4:
                continue  # ignora linhas corrompidas
            alunos.append({
                "id": partes[0],
                "nome": partes[1],
                "telefone": partes[2],
                "email": partes[3],
            })
    return alunos


def salvar_alunos(alunos):
    """Grava a lista de alunos (sobrescrevendo o arquivo)."""
    with open(ARQUIVO_ALUNOS, "w", encoding="utf-8") as f:
        for a in alunos:
            f.write(f"{a['id']};{a['nome']};{a['telefone']};{a['email']}\n")


def ler_notas():
    """Lê o arquivo de notas e retorna uma lista de dicionários."""
    notas = []
    if not os.path.exists(ARQUIVO_NOTAS):
        return notas

    with open(ARQUIVO_NOTAS, "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if not linha:
                continue
            partes = linha.split(";")
            if len(partes) != 3:
                continue
            notas.append({
                "id_aluno": partes[0],
                "disciplina": partes[1],
                "nota": partes[2],
            })
    return notas


def salvar_notas(notas):
    """Grava a lista de notas (sobrescrevendo o arquivo)."""
    with open(ARQUIVO_NOTAS, "w", encoding="utf-8") as f:
        for n in notas:
            f.write(f"{n['id_aluno']};{n['disciplina']};{n['nota']}\n")


def buscar_aluno_por_id(id_aluno, alunos=None):
    """Retorna o dicionário do aluno com o ID informado, ou None."""
    alunos = alunos if alunos is not None else ler_alunos()
    for a in alunos:
        if a["id"] == id_aluno:
            return a
    return None


def buscar_alunos_por_nome(nome, alunos=None):
    """Retorna lista de alunos cujo nome contém o texto informado
    (busca case-insensitive e parcial)."""
    alunos = alunos if alunos is not None else ler_alunos()
    nome = nome.strip().lower()
    return [a for a in alunos if nome in a["nome"].lower()]


# ---------------------------------------------------------------------------
# FUNCIONALIDADES OBRIGATÓRIAS
# ---------------------------------------------------------------------------

def cadastrar_aluno():
    print("\n--- Cadastro de Aluno ---")
    alunos = ler_alunos()

    id_aluno = input("ID do aluno: ").strip()

    # Impede IDs duplicados
    if buscar_aluno_por_id(id_aluno, alunos):
        print(f"Erro: já existe um aluno com o ID '{id_aluno}'.")
        return

    nome = input("Nome: ").strip()
    telefone = input("Telefone: ").strip()
    email = input("E-mail: ").strip()

    alunos.append({
        "id": id_aluno,
        "nome": nome,
        "telefone": telefone,
        "email": email,
    })
    salvar_alunos(alunos)
    print(f"Aluno '{nome}' cadastrado com sucesso!")


def listar_alunos():
    print("\n--- Lista de Alunos ---")
    alunos = ler_alunos()
    if not alunos:
        print("Nenhum aluno cadastrado.")
        return

    for a in alunos:
        print(f"ID: {a['id']} | Nome: {a['nome']} | "
              f"Telefone: {a['telefone']} | E-mail: {a['email']}")


def buscar_aluno():
    print("\n--- Buscar Aluno ---")
    nome = input("Digite o nome (ou parte dele): ").strip()
    encontrados = buscar_alunos_por_nome(nome)

    if not encontrados:
        print("Nenhum aluno encontrado com esse nome.")
        return

    for a in encontrados:
        print(f"ID: {a['id']} | Nome: {a['nome']} | "
              f"Telefone: {a['telefone']} | E-mail: {a['email']}")


def cadastrar_nota():
    print("\n--- Cadastro de Nota ---")
    id_aluno = input("ID do aluno: ").strip()

    aluno = buscar_aluno_por_id(id_aluno)
    if not aluno:
        print(f"Erro: não existe aluno cadastrado com o ID '{id_aluno}'. "
              "A nota não pode ser cadastrada.")
        return

    disciplina = input("Disciplina: ").strip()
    nota_str = input("Nota: ").strip()

    try:
        nota_valor = float(nota_str.replace(",", "."))
    except ValueError:
        print("Erro: nota inválida. Digite um número (ex: 8.5).")
        return

    notas = ler_notas()
    notas.append({
        "id_aluno": id_aluno,
        "disciplina": disciplina,
        "nota": str(nota_valor),
    })
    salvar_notas(notas)
    print(f"Nota de {aluno['nome']} em {disciplina} cadastrada com sucesso!")


def consultar_nota():
    print("\n--- Consultar Nota ---")
    nome = input("Digite o nome do aluno: ").strip()
    disciplina = input("Digite a disciplina: ").strip()

    alunos_encontrados = buscar_alunos_por_nome(nome)
    if not alunos_encontrados:
        print("Aluno não encontrado.")
        return
    if len(alunos_encontrados) > 1:
        print("Mais de um aluno encontrado com esse nome:")
        for a in alunos_encontrados:
            print(f"  ID: {a['id']} | Nome: {a['nome']}")
        id_aluno = input("Digite o ID do aluno desejado: ").strip()
        aluno = buscar_aluno_por_id(id_aluno, alunos_encontrados)
        if not aluno:
            print("ID inválido.")
            return
    else:
        aluno = alunos_encontrados[0]

    notas = ler_notas()
    nota_encontrada = None
    for n in notas:
        if n["id_aluno"] == aluno["id"] and n["disciplina"].lower() == disciplina.lower():
            nota_encontrada = n
            break

    if not nota_encontrada:
        print(f"Não foi encontrada nota de {aluno['nome']} em {disciplina}.")
        return

    print(f"\nAluno: {aluno['nome']}")
    print(f"Disciplina: {nota_encontrada['disciplina']}")
    print(f"Nota: {nota_encontrada['nota']}")


# ---------------------------------------------------------------------------
# DESAFIOS EXTRAS
# ---------------------------------------------------------------------------

def listar_notas_aluno():
    print("\n--- Notas de um Aluno ---")
    nome = input("Digite o nome do aluno: ").strip()
    alunos_encontrados = buscar_alunos_por_nome(nome)

    if not alunos_encontrados:
        print("Aluno não encontrado.")
        return
    aluno = alunos_encontrados[0]

    notas = [n for n in ler_notas() if n["id_aluno"] == aluno["id"]]
    if not notas:
        print(f"{aluno['nome']} ainda não possui notas cadastradas.")
        return

    print(f"\nNotas de {aluno['nome']}:")
    for n in notas:
        print(f"  {n['disciplina']}: {n['nota']}")


def calcular_media_aluno():
    print("\n--- Média de um Aluno ---")
    nome = input("Digite o nome do aluno: ").strip()
    alunos_encontrados = buscar_alunos_por_nome(nome)

    if not alunos_encontrados:
        print("Aluno não encontrado.")
        return
    aluno = alunos_encontrados[0]

    notas = [n for n in ler_notas() if n["id_aluno"] == aluno["id"]]
    if not notas:
        print(f"{aluno['nome']} ainda não possui notas cadastradas.")
        return

    valores = [float(n["nota"]) for n in notas]
    media = sum(valores) / len(valores)
    print(f"Média de {aluno['nome']}: {media:.2f}")


def editar_nota():
    print("\n--- Editar Nota ---")
    nome = input("Digite o nome do aluno: ").strip()
    disciplina = input("Digite a disciplina: ").strip()

    alunos_encontrados = buscar_alunos_por_nome(nome)
    if not alunos_encontrados:
        print("Aluno não encontrado.")
        return
    aluno = alunos_encontrados[0]

    notas = ler_notas()
    for n in notas:
        if n["id_aluno"] == aluno["id"] and n["disciplina"].lower() == disciplina.lower():
            nova_nota = input(f"Nova nota (atual: {n['nota']}): ").strip()
            try:
                n["nota"] = str(float(nova_nota.replace(",", ".")))
            except ValueError:
                print("Erro: nota inválida.")
                return
            salvar_notas(notas)
            print("Nota atualizada com sucesso!")
            return

    print("Nota não encontrada para esse aluno/disciplina.")


def excluir_nota():
    print("\n--- Excluir Nota ---")
    nome = input("Digite o nome do aluno: ").strip()
    disciplina = input("Digite a disciplina: ").strip()

    alunos_encontrados = buscar_alunos_por_nome(nome)
    if not alunos_encontrados:
        print("Aluno não encontrado.")
        return
    aluno = alunos_encontrados[0]

    notas = ler_notas()
    nova_lista = [
        n for n in notas
        if not (n["id_aluno"] == aluno["id"] and n["disciplina"].lower() == disciplina.lower())
    ]

    if len(nova_lista) == len(notas):
        print("Nota não encontrada para esse aluno/disciplina.")
        return

    salvar_notas(nova_lista)
    print("Nota excluída com sucesso!")


def buscar_alunos_por_disciplina():
    print("\n--- Alunos por Disciplina ---")
    disciplina = input("Digite a disciplina: ").strip()

    notas = [n for n in ler_notas() if n["disciplina"].lower() == disciplina.lower()]
    if not notas:
        print("Nenhum aluno encontrado nessa disciplina.")
        return

    alunos = ler_alunos()
    print(f"\nAlunos matriculados em {disciplina}:")
    for n in notas:
        aluno = buscar_aluno_por_id(n["id_aluno"], alunos)
        nome = aluno["nome"] if aluno else f"(aluno ID {n['id_aluno']} não encontrado)"
        print(f"  {nome} — Nota: {n['nota']}")


def buscar_alunos_nota_acima():
    print("\n--- Alunos com Nota Acima de um Valor ---")
    disciplina = input("Digite a disciplina: ").strip()
    valor_str = input("Nota mínima: ").strip()

    try:
        valor_minimo = float(valor_str.replace(",", "."))
    except ValueError:
        print("Erro: valor inválido.")
        return

    notas = [
        n for n in ler_notas()
        if n["disciplina"].lower() == disciplina.lower() and float(n["nota"]) > valor_minimo
    ]

    if not notas:
        print(f"Nenhum aluno com nota acima de {valor_minimo} em {disciplina}.")
        return

    alunos = ler_alunos()
    print(f"\nAlunos com nota acima de {valor_minimo} em {disciplina}:")
    for n in notas:
        aluno = buscar_aluno_por_id(n["id_aluno"], alunos)
        nome = aluno["nome"] if aluno else f"(aluno ID {n['id_aluno']} não encontrado)"
        print(f"  {nome} — Nota: {n['nota']}")


# ---------------------------------------------------------------------------
# MENU PRINCIPAL
# ---------------------------------------------------------------------------

def menu():
    opcoes = {
        "1": ("Cadastrar aluno", cadastrar_aluno),
        "2": ("Listar alunos", listar_alunos),
        "3": ("Buscar aluno por nome", buscar_aluno),
        "4": ("Cadastrar nota", cadastrar_nota),
        "5": ("Consultar nota", consultar_nota),
        "6": ("Listar notas de um aluno", listar_notas_aluno),
        "7": ("Calcular média de um aluno", calcular_media_aluno),
        "8": ("Editar nota", editar_nota),
        "9": ("Excluir nota", excluir_nota),
        "10": ("Buscar alunos por disciplina", buscar_alunos_por_disciplina),
        "11": ("Buscar alunos com nota acima de um valor", buscar_alunos_nota_acima),
        "0": ("Sair", None),
    }

    while True:
        print("\n========== SISTEMA ACADÊMICO ==========")
        for chave, (descricao, _) in opcoes.items():
            print(f"{chave} - {descricao}")
        print("========================================")

        escolha = input("Escolha uma opção: ").strip()

        if escolha == "0":
            print("Encerrando o programa. Até logo!")
            break

        if escolha in opcoes:
            _, funcao = opcoes[escolha]
            funcao()
        else:
            print("Opção inválida. Tente novamente.")


if __name__ == "__main__":
    menu()
