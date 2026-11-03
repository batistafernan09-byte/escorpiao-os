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
falhas = []
for nome, arq, url in pedidos:
    alvo = os.path.join(dest, arq)
    if os.path.exists(alvo) and os.path.getsize(alvo) > 0:
        continue
    r = subprocess.run(["wget", "-q", "-T", "60", "-t", "5", "-O", alvo + ".parcial", url])
    if r.returncode == 0:
        os.replace(alvo + ".parcial", alvo)
    else:
        if os.path.exists(alvo + ".parcial"):
            os.remove(alvo + ".parcial")
        falhas.append("%s: %s" % (nome, url))
print("%d arquivos pedidos pelos scripts; %d falharam" % (len(pedidos), len(falhas)))
for f in falhas:
    print("  FALHOU", f)
sys.exit(1 if falhas else 0)
