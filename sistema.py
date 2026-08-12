"""
Sistema Acadêmico com Arquivos (sem banco de dados)
====================================================
Relaciona duas entidades (Alunos e Notas) usando arquivos de texto,
onde o campo ID_ALUNO conecta os registros de notas.txt aos registros
de alunos.txt.

Arquivos utilizados:
- alunos.txt -> ID;NOME;TELEFONE;EMAIL
- notas.txt  -> ID_ALUNO;DISCIPLINA;NOTA
"""

import os

ARQUIVO_ALUNOS = "alunos.txt"
ARQUIVO_NOTAS = "notas.txt"


# ---------------------------------------------------------------------------
# Funções de apoio - leitura e escrita dos arquivos
# ---------------------------------------------------------------------------

def garantir_arquivos():
    """Cria os arquivos caso ainda não existam, para não quebrar a leitura."""
    for arquivo in (ARQUIVO_ALUNOS, ARQUIVO_NOTAS):
        if not os.path.exists(arquivo):
            open(arquivo, "w", encoding="utf-8").close()


def carregar_alunos():
    """Lê alunos.txt e devolve uma lista de dicionários."""
    alunos = []
    with open(ARQUIVO_ALUNOS, "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if not linha:
                continue
            id_, nome, telefone, email = linha.split(";")
            alunos.append({
                "id": id_,
                "nome": nome,
                "telefone": telefone,
                "email": email,
            })
    return alunos


def salvar_alunos(alunos):
    """Reescreve alunos.txt inteiro a partir da lista em memória."""
    with open(ARQUIVO_ALUNOS, "w", encoding="utf-8") as f:
        for a in alunos:
            f.write(f"{a['id']};{a['nome']};{a['telefone']};{a['email']}\n")


def carregar_notas():
    """Lê notas.txt e devolve uma lista de dicionários."""
    notas = []
    with open(ARQUIVO_NOTAS, "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if not linha:
                continue
            id_aluno, disciplina, nota = linha.split(";")
            notas.append({
                "id_aluno": id_aluno,
                "disciplina": disciplina,
                "nota": float(nota),
            })
    return notas


def salvar_notas(notas):
    """Reescreve notas.txt inteiro a partir da lista em memória."""
    with open(ARQUIVO_NOTAS, "w", encoding="utf-8") as f:
        for n in notas:
            f.write(f"{n['id_aluno']};{n['disciplina']};{n['nota']}\n")


# ---------------------------------------------------------------------------
# Funções auxiliares de busca
# ---------------------------------------------------------------------------

def buscar_aluno_por_id(alunos, id_):
    for a in alunos:
        if a["id"] == id_:
            return a
    return None


def buscar_aluno_por_nome(alunos, nome):
    """Busca exata (case-insensitive). Retorna o primeiro encontrado."""
    nome_normalizado = nome.strip().lower()
    for a in alunos:
        if a["nome"].strip().lower() == nome_normalizado:
            return a
    return None


def buscar_alunos_por_nome_parcial(alunos, termo):
    """Busca por trecho do nome, útil para listar candidatos."""
    termo = termo.strip().lower()
    return [a for a in alunos if termo in a["nome"].lower()]


# ---------------------------------------------------------------------------
# 1. Cadastrar aluno
# ---------------------------------------------------------------------------

def cadastrar_aluno():
    alunos = carregar_alunos()

    id_ = input("ID do aluno: ").strip()
    if buscar_aluno_por_id(alunos, id_):
        print(f">> Já existe um aluno com o ID '{id_}'. Cadastro cancelado.\n")
        return

    nome = input("Nome: ").strip()
    telefone = input("Telefone: ").strip()
    email = input("E-mail: ").strip()

    alunos.append({"id": id_, "nome": nome, "telefone": telefone, "email": email})
    salvar_alunos(alunos)
    print(f">> Aluno '{nome}' cadastrado com sucesso!\n")


# ---------------------------------------------------------------------------
# 2. Listar alunos
# ---------------------------------------------------------------------------

def listar_alunos():
    alunos = carregar_alunos()
    if not alunos:
        print(">> Nenhum aluno cadastrado.\n")
        return

    print("\n{:<5} {:<20} {:<15} {:<25}".format("ID", "Nome", "Telefone", "E-mail"))
    print("-" * 65)
    for a in alunos:
        print("{:<5} {:<20} {:<15} {:<25}".format(a["id"], a["nome"], a["telefone"], a["email"]))
    print()


# ---------------------------------------------------------------------------
# 3. Buscar aluno
# ---------------------------------------------------------------------------

def buscar_aluno():
    alunos = carregar_alunos()
    nome = input("Digite o nome (ou parte dele) para buscar: ").strip()
    encontrados = buscar_alunos_por_nome_parcial(alunos, nome)

    if not encontrados:
        print(">> Nenhum aluno encontrado.\n")
        return

    print()
    for a in encontrados:
        print(f"ID: {a['id']} | Nome: {a['nome']} | Telefone: {a['telefone']} | E-mail: {a['email']}")
    print()


# ---------------------------------------------------------------------------
# 4. Cadastrar nota
# ---------------------------------------------------------------------------

def cadastrar_nota():
    alunos = carregar_alunos()
    nome = input("Nome do aluno: ").strip()
    aluno = buscar_aluno_por_nome(alunos, nome)

    if not aluno:
        print(">> Aluno não encontrado. Não é possível cadastrar nota para aluno inexistente.\n")
        return

    disciplina = input("Disciplina: ").strip()
    try:
        nota = float(input("Nota: ").strip().replace(",", "."))
    except ValueError:
        print(">> Nota inválida. Use um número (ex: 8.5).\n")
        return

    notas = carregar_notas()
    notas.append({"id_aluno": aluno["id"], "disciplina": disciplina, "nota": nota})
    salvar_notas(notas)
    print(f">> Nota de {aluno['nome']} em {disciplina} cadastrada com sucesso!\n")


# ---------------------------------------------------------------------------
# 5. Consultar nota (relacionamento entre os dois arquivos)
# ---------------------------------------------------------------------------

def consultar_nota():
    alunos = carregar_alunos()
    nome = input("Digite o nome do aluno: ").strip()
    aluno = buscar_aluno_por_nome(alunos, nome)

    if not aluno:
        print(">> Aluno não encontrado.\n")
        return

    disciplina = input("Digite a disciplina: ").strip()
    notas = carregar_notas()

    for n in notas:
        if n["id_aluno"] == aluno["id"] and n["disciplina"].strip().lower() == disciplina.strip().lower():
            print(f"\nAluno: {aluno['nome']}")
            print(f"Disciplina: {n['disciplina']}")
            print(f"Nota: {n['nota']}\n")
            return

    print(">> Nenhuma nota encontrada para esse aluno nessa disciplina.\n")


# ---------------------------------------------------------------------------
# DESAFIO EXTRA 1 - Listar todas as notas de um aluno
# ---------------------------------------------------------------------------

def listar_notas_aluno():
    alunos = carregar_alunos()
    nome = input("Digite o nome do aluno: ").strip()
    aluno = buscar_aluno_por_nome(alunos, nome)

    if not aluno:
        print(">> Aluno não encontrado.\n")
        return

    notas = carregar_notas()
    notas_aluno = [n for n in notas if n["id_aluno"] == aluno["id"]]

    if not notas_aluno:
        print(f">> {aluno['nome']} ainda não possui notas cadastradas.\n")
        return

    print(f"\nNotas de {aluno['nome']}:")
    for n in notas_aluno:
        print(f"  - {n['disciplina']}: {n['nota']}")
    print()


# ---------------------------------------------------------------------------
# DESAFIO EXTRA 2 - Calcular a média de um aluno
# ---------------------------------------------------------------------------

def calcular_media():
    alunos = carregar_alunos()
    nome = input("Digite o nome do aluno: ").strip()
    aluno = buscar_aluno_por_nome(alunos, nome)

    if not aluno:
        print(">> Aluno não encontrado.\n")
        return

    notas = carregar_notas()
    notas_aluno = [n["nota"] for n in notas if n["id_aluno"] == aluno["id"]]

    if not notas_aluno:
        print(f">> {aluno['nome']} não possui notas cadastradas para calcular a média.\n")
        return

    media = sum(notas_aluno) / len(notas_aluno)
    print(f"\nAluno: {aluno['nome']}")
    print(f"Quantidade de notas: {len(notas_aluno)}")
    print(f"Média: {media:.2f}\n")


# ---------------------------------------------------------------------------
# DESAFIO EXTRA 3 - Editar uma nota
# ---------------------------------------------------------------------------

def editar_nota():
    alunos = carregar_alunos()
    nome = input("Digite o nome do aluno: ").strip()
    aluno = buscar_aluno_por_nome(alunos, nome)

    if not aluno:
        print(">> Aluno não encontrado.\n")
        return

    disciplina = input("Digite a disciplina da nota que deseja editar: ").strip()
    notas = carregar_notas()

    for n in notas:
        if n["id_aluno"] == aluno["id"] and n["disciplina"].strip().lower() == disciplina.strip().lower():
            print(f"Nota atual: {n['nota']}")
            try:
                nova_nota = float(input("Digite a nova nota: ").strip().replace(",", "."))
            except ValueError:
                print(">> Nota inválida. Edição cancelada.\n")
                return
            n["nota"] = nova_nota
            salvar_notas(notas)
            print(f">> Nota de {aluno['nome']} em {disciplina} atualizada para {nova_nota}.\n")
            return

    print(">> Nenhuma nota encontrada para esse aluno nessa disciplina.\n")


# ---------------------------------------------------------------------------
# Menu principal
# ---------------------------------------------------------------------------

def menu():
    opcoes = {
        "1": ("Cadastrar aluno", cadastrar_aluno),
        "2": ("Listar alunos", listar_alunos),
        "3": ("Buscar aluno", buscar_aluno),
        "4": ("Cadastrar nota", cadastrar_nota),
        "5": ("Consultar nota", consultar_nota),
        "6": ("Listar todas as notas de um aluno", listar_notas_aluno),
        "7": ("Calcular média de um aluno", calcular_media),
        "8": ("Editar uma nota", editar_nota),
        "0": ("Sair", None),
    }

    garantir_arquivos()

    while True:
        print("=" * 45)
        print(" SISTEMA ACADÊMICO - ALUNOS E NOTAS ")
        print("=" * 45)
        for chave, (descricao, _) in opcoes.items():
            print(f"{chave} - {descricao}")
        print("=" * 45)

        escolha = input("Escolha uma opção: ").strip()

        if escolha == "0":
            print("Encerrando o sistema. Até logo!")
            break

        item = opcoes.get(escolha)
        if not item:
            print(">> Opção inválida.\n")
            continue

        _, funcao = item
        print()
        funcao()


if __name__ == "__main__":
    menu()
