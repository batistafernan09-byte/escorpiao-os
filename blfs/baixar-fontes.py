#!/usr/bin/env python3
"""
Baixa, no computador do GitHub (fora do chroot), todos os arquivos que os scripts do BLFS pedem — os mesmos endereços
e nomes que estão no livro — para a pasta /sources do sistema novo. Assim nada precisa baixar lá dentro.
Uso: baixar-fontes.py <pasta-de-scripts> <pasta-sources>
"""
import os
import re
import subprocess
import sys

scripts, dest = sys.argv[1], sys.argv[2]
os.makedirs(dest, exist_ok=True)
pedidos = []
for nome in sorted(os.listdir(scripts)):
    atual = None
    for linha in open(os.path.join(scripts, nome), encoding="utf-8", errors="replace"):
        m = re.match(r'^(PACKAGE\d*|PATCH\d*)=(\S+)\s*$', linha.strip())
        if m:
            atual = m.group(2)
            continue
        m = re.search(r'wget -T \d+ -t \d+ "([^"]+)"', linha)
        if m and atual:
            pedidos.append((nome, atual, m.group(1)))
            atual = None
def candidatos(arq, url):
    """O endereço do livro primeiro; depois espelhos para os casos que somem/caem com o tempo."""
    yield url
    # Patches do BLFS: o diretório 'svn' (versão em desenvolvimento) é removido depois do lançamento;
    # a versão fixa 12.4 continua no mesmo servidor e no espelho anduin.
    if "/patches/blfs/svn/" in url:
        yield url.replace("/patches/blfs/svn/", "/patches/blfs/12.4/")
        yield url.replace("https://www.linuxfromscratch.org/patches/blfs/svn/",
                          "https://anduin.linuxfromscratch.org/patches/blfs/12.4/")
    # docbook-xml 4.5: o docbook.org vive fora do ar; tenta o OASIS (origem) e o espelho do LFS.
    if "docbook-xml-4.5" in arq:
        yield "https://www.oasis-open.org/docbook/xml/4.5/" + arq
        yield "https://anduin.linuxfromscratch.org/BLFS/docbook-xml/" + arq
    # xmlto: o endpoint 'archive' do pagure costuma dar 500; o 'releases' é o estável.
    if arq.startswith("xmlto-"):
        yield "https://releases.pagure.org/xmlto/" + arq
        yield "https://anduin.linuxfromscratch.org/BLFS/xmlto/" + arq

def baixa(arq, url, alvo):
    for u in candidatos(arq, url):
        r = subprocess.run(["wget", "-q", "-T", "45", "-t", "3", "-O", alvo + ".parcial", u])
        if r.returncode == 0 and os.path.exists(alvo + ".parcial") and os.path.getsize(alvo + ".parcial") > 0:
            os.replace(alvo + ".parcial", alvo)
            return True
        if os.path.exists(alvo + ".parcial"):
            os.remove(alvo + ".parcial")
    return False

falhas = []
for nome, arq, url in pedidos:
    alvo = os.path.join(dest, arq)
    if os.path.exists(alvo) and os.path.getsize(alvo) > 0:
        continue
    if not baixa(arq, url, alvo):
        falhas.append("%s: %s" % (nome, url))
print("%d arquivos pedidos pelos scripts; %d falharam" % (len(pedidos), len(falhas)))
for f in falhas:
    print("  FALHOU", f)
sys.exit(1 if falhas else 0)
