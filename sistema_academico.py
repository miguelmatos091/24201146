"""
Sistema Acadêmico - Cadastro de Alunos e Notas usando Arquivos
================================================================
Armazena dados em dois arquivos texto (alunos.txt e notas.txt),
relacionando as entidades através do campo ID_ALUNO.

Nenhum banco de dados é utilizado - apenas leitura/escrita de arquivos.
"""

import os

ARQUIVO_ALUNOS = "alunos.txt"
ARQUIVO_NOTAS = "notas.txt"


# =========================================================
# FUNÇÕES DE APOIO - LEITURA E ESCRITA DOS ARQUIVOS
# =========================================================

def garantir_arquivos():
    """Cria os arquivos caso ainda não existam."""
    for arquivo in (ARQUIVO_ALUNOS, ARQUIVO_NOTAS):
        if not os.path.exists(arquivo):
            open(arquivo, "w", encoding="utf-8").close()


def carregar_alunos():
    """Lê alunos.txt e retorna uma lista de dicionários."""
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
                "email": email
            })
    return alunos


def salvar_alunos(alunos):
    """Regrava alunos.txt inteiro a partir da lista de dicionários."""
    with open(ARQUIVO_ALUNOS, "w", encoding="utf-8") as f:
        for a in alunos:
            f.write(f"{a['id']};{a['nome']};{a['telefone']};{a['email']}\n")


def carregar_notas():
    """Lê notas.txt e retorna uma lista de dicionários."""
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
                "nota": float(nota)
            })
    return notas


def salvar_notas(notas):
    """Regrava notas.txt inteiro a partir da lista de dicionários."""
    with open(ARQUIVO_NOTAS, "w", encoding="utf-8") as f:
        for n in notas:
            f.write(f"{n['id_aluno']};{n['disciplina']};{n['nota']}\n")


# =========================================================
# FUNÇÕES DE ALUNO
# =========================================================

def cadastrar_aluno():
    alunos = carregar_alunos()

    id_ = input("ID do aluno: ").strip()

    # Impede IDs duplicados
    if any(a["id"] == id_ for a in alunos):
        print(f"❌ Já existe um aluno cadastrado com o ID '{id_}'.\n")
        return

    nome = input("Nome: ").strip()
    telefone = input("Telefone: ").strip()
    email = input("E-mail: ").strip()

    alunos.append({"id": id_, "nome": nome, "telefone": telefone, "email": email})
    salvar_alunos(alunos)
    print(f"✅ Aluno '{nome}' cadastrado com sucesso.\n")


def listar_alunos():
    alunos = carregar_alunos()
    if not alunos:
        print("Nenhum aluno cadastrado.\n")
        return

    print("\n--- LISTA DE ALUNOS ---")
    for a in alunos:
        print(f"ID: {a['id']} | Nome: {a['nome']} | Tel: {a['telefone']} | Email: {a['email']}")
    print()


def buscar_aluno_por_nome(nome_busca=None, silencioso=False):
    """Retorna o dicionário do aluno encontrado (ou None)."""
    alunos = carregar_alunos()
    if nome_busca is None:
        nome_busca = input("Digite o nome do aluno: ").strip()

    encontrados = [a for a in alunos if a["nome"].lower() == nome_busca.lower()]

    if not encontrados:
        if not silencioso:
            print(f"❌ Nenhum aluno encontrado com o nome '{nome_busca}'.\n")
        return None

    if not silencioso:
        print("\n--- ALUNO ENCONTRADO ---")
        for a in encontrados:
            print(f"ID: {a['id']} | Nome: {a['nome']} | Tel: {a['telefone']} | Email: {a['email']}")
        print()

    return encontrados[0]


# =========================================================
# FUNÇÕES DE NOTA
# =========================================================

def cadastrar_nota():
    aluno = buscar_aluno_por_nome(silencioso=True)

    if aluno is None:
        print("❌ Aluno não encontrado. Cadastre o aluno antes de lançar a nota.\n")
        return

    disciplina = input("Disciplina: ").strip()

    while True:
        try:
            nota = float(input("Nota: ").strip())
            break
        except ValueError:
            print("Valor inválido, digite um número (ex: 9.5).")

    notas = carregar_notas()
    notas.append({"id_aluno": aluno["id"], "disciplina": disciplina, "nota": nota})
    salvar_notas(notas)
    print(f"✅ Nota de {aluno['nome']} em {disciplina} cadastrada com sucesso.\n")


def consultar_nota():
    aluno = buscar_aluno_por_nome(silencioso=True)
    if aluno is None:
        print("❌ Aluno não encontrado.\n")
        return

    disciplina = input("Digite a disciplina: ").strip()

    notas = carregar_notas()
    registro = next(
        (n for n in notas if n["id_aluno"] == aluno["id"] and n["disciplina"].lower() == disciplina.lower()),
        None
    )

    if registro is None:
        print(f"❌ Não foi encontrada nota de {aluno['nome']} em {disciplina}.\n")
        return

    print("\n--- RESULTADO ---")
    print(f"Aluno: {aluno['nome']}")
    print(f"Disciplina: {registro['disciplina']}")
    print(f"Nota: {registro['nota']}\n")


# =========================================================
# DESAFIOS EXTRAS
# =========================================================

def listar_notas_de_aluno():
    aluno = buscar_aluno_por_nome(silencioso=True)
    if aluno is None:
        print("❌ Aluno não encontrado.\n")
        return

    notas = [n for n in carregar_notas() if n["id_aluno"] == aluno["id"]]
    if not notas:
        print(f"{aluno['nome']} ainda não possui notas cadastradas.\n")
        return

    print(f"\n--- NOTAS DE {aluno['nome'].upper()} ---")
    for n in notas:
        print(f"{n['disciplina']}: {n['nota']}")
    print()


def calcular_media_aluno():
    aluno = buscar_aluno_por_nome(silencioso=True)
    if aluno is None:
        print("❌ Aluno não encontrado.\n")
        return

    notas = [n["nota"] for n in carregar_notas() if n["id_aluno"] == aluno["id"]]
    if not notas:
        print(f"{aluno['nome']} ainda não possui notas cadastradas.\n")
        return

    media = sum(notas) / len(notas)
    print(f"Média de {aluno['nome']}: {media:.2f}\n")


def editar_nota():
    aluno = buscar_aluno_por_nome(silencioso=True)
    if aluno is None:
        print("❌ Aluno não encontrado.\n")
        return

    disciplina = input("Disciplina da nota a editar: ").strip()
    notas = carregar_notas()

    registro = next(
        (n for n in notas if n["id_aluno"] == aluno["id"] and n["disciplina"].lower() == disciplina.lower()),
        None
    )

    if registro is None:
        print("❌ Registro de nota não encontrado.\n")
        return

    while True:
        try:
            nova_nota = float(input("Nova nota: ").strip())
            break
        except ValueError:
            print("Valor inválido, digite um número (ex: 9.5).")

    registro["nota"] = nova_nota
    salvar_notas(notas)
    print("✅ Nota atualizada com sucesso.\n")


def excluir_nota():
    aluno = buscar_aluno_por_nome(silencioso=True)
    if aluno is None:
        print("❌ Aluno não encontrado.\n")
        return

    disciplina = input("Disciplina da nota a excluir: ").strip()
    notas = carregar_notas()

    tamanho_original = len(notas)
    notas = [
        n for n in notas
        if not (n["id_aluno"] == aluno["id"] and n["disciplina"].lower() == disciplina.lower())
    ]

    if len(notas) == tamanho_original:
        print("❌ Registro de nota não encontrado.\n")
        return

    salvar_notas(notas)
    print("✅ Nota excluída com sucesso.\n")


def buscar_alunos_por_disciplina():
    disciplina = input("Disciplina: ").strip()
    alunos = {a["id"]: a for a in carregar_alunos()}
    notas = [n for n in carregar_notas() if n["disciplina"].lower() == disciplina.lower()]

    if not notas:
        print(f"Nenhum aluno encontrado cursando '{disciplina}'.\n")
        return

    print(f"\n--- ALUNOS EM {disciplina.upper()} ---")
    for n in notas:
        aluno = alunos.get(n["id_aluno"])
        nome = aluno["nome"] if aluno else "(aluno não encontrado)"
        print(f"{nome} - Nota: {n['nota']}")
    print()


def buscar_alunos_por_nota_minima():
    while True:
        try:
            valor_min = float(input("Nota mínima: ").strip())
            break
        except ValueError:
            print("Valor inválido, digite um número (ex: 7.0).")

    alunos = {a["id"]: a for a in carregar_alunos()}
    notas = [n for n in carregar_notas() if n["nota"] >= valor_min]

    if not notas:
        print(f"Nenhum registro de nota >= {valor_min}.\n")
        return

    print(f"\n--- NOTAS >= {valor_min} ---")
    for n in notas:
        aluno = alunos.get(n["id_aluno"])
        nome = aluno["nome"] if aluno else "(aluno não encontrado)"
        print(f"{nome} | {n['disciplina']}: {n['nota']}")
    print()


# =========================================================
# MENU PRINCIPAL
# =========================================================

def menu():
    opcoes = """
=====================================
      SISTEMA ACADÊMICO - MENU
=====================================
 1  - Cadastrar aluno
 2  - Listar alunos
 3  - Buscar aluno por nome
 4  - Cadastrar nota
 5  - Consultar nota
 6  - Listar notas de um aluno
 7  - Calcular média de um aluno
 8  - Editar uma nota
 9  - Excluir uma nota
10  - Buscar alunos por disciplina
11  - Buscar alunos com nota >= X
 0  - Sair
=====================================
"""
    print(opcoes)


def main():
    garantir_arquivos()

    acoes = {
        "1": cadastrar_aluno,
        "2": listar_alunos,
        "3": buscar_aluno_por_nome,
        "4": cadastrar_nota,
        "5": consultar_nota,
        "6": listar_notas_de_aluno,
        "7": calcular_media_aluno,
        "8": editar_nota,
        "9": excluir_nota,
        "10": buscar_alunos_por_disciplina,
        "11": buscar_alunos_por_nota_minima,
    }

    while True:
        menu()
        escolha = input("Escolha uma opção: ").strip()

        if escolha == "0":
            print("Encerrando o sistema. Os dados foram salvos nos arquivos .txt.")
            break

        acao = acoes.get(escolha)
        if acao:
            acao()
        else:
            print("Opção inválida.\n")


if __name__ == "__main__":
    main()
