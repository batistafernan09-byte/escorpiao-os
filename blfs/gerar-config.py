#!/usr/bin/env python3
"""
Escreve a configuração da ferramenta do BLFS (jhalfs) sem o menu: QUAIS programas queremos e como montar.
A ferramenta acha sozinha as dependências (o que cada programa precisa) e a ordem certa, lendo o livro BLFS.
Uso: gerar-config.py <blfs_root> <arquivo-com-a-lista-de-programas> [nivel-de-dependencias 1..4]
"""
import os
import sys

root, lista = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
nivel = sys.argv[3] if len(sys.argv) > 3 else "1"
sys.path.insert(0, os.path.join(root, "menu"))
os.environ["CONFIG_"] = ""
os.environ["KCONFIG_CONFIG"] = os.path.join(root, "configuration")
import kconfiglib  # noqa: E402

os.chdir(root)
k = kconfiglib.Kconfig("Config.in", warn_to_stderr=False)
alvos = [l.split("#")[0].strip() for l in open(lista, encoding="utf-8")]
alvos = [a for a in alvos if a]
faltam = [a for a in alvos if ("CONFIG_" + a) not in k.syms]
if faltam:
    sys.exit("estes programas não existem no livro BLFS: " + ", ".join(faltam))
# os pacotes ficam dentro de "menus" do livro (um por capítulo): abre todos os menus e marca SÓ os pedidos
for nome, sym in k.syms.items():
    if nome.startswith("MENU_"):
        sym.set_value("y")
for nome, sym in k.syms.items():
    if nome.startswith("CONFIG_"):
        sym.set_value("y" if nome[7:] in alvos else "n")
ok = {
    "DEPLVL_" + nivel: "y",
    "LANGUAGE": "pt_BR.UTF-8",
    "SUDO": "n",                 # dentro do chroot, como root
    "SRC_ARCHIVE": "/sources",
    "BUILD_ROOT": "/sources/build",
    "DEL_LA_FILES": "y",
    "JOBS": "0",                 # 0 = todos os processadores
}
for n, v in ok.items():
    if n not in k.syms:
        sys.exit("opção desconhecida: " + n)
    k.syms[n].set_value(v)
k.write_config(os.path.join(root, "configuration"))
nao = [a for a in alvos if k.syms["CONFIG_" + a].str_value != "y"]
if nao:
    sys.exit("não consegui marcar: " + ", ".join(nao))
print("configuração do BLFS gravada: %d programas pedidos, dependências nível %s" % (len(alvos), nivel))
