#!/usr/bin/env python3
"""
Escreve o arquivo `configuration` do jhalfs (a ferramenta oficial do LFS que lê o livro e roda os comandos) sem o menu.
Uso: python3 gerar-config.py <pasta-do-jhalfs> <pasta-do-livro-arm64> <pasta-de-montagem> <arquivo-config-do-kernel> <pasta-dos-fontes>
"""
import os
import sys

jh, book, builddir, kconfig, sources = sys.argv[1:6]
sys.path.insert(0, os.path.join(jh, "menu"))
os.environ["CONFIG_"] = ""                       # o jhalfs usa nomes sem o prefixo CONFIG_
os.environ["KCONFIG_CONFIG"] = os.path.join(jh, "configuration")
import kconfiglib  # noqa: E402

os.chdir(jh)
k = kconfiglib.Kconfig("Config.in", warn_to_stderr=False)

ESCOLHAS = {
    "BOOK_LFS": "y",                 # LFS com SysVinit (mais simples e leve que o systemd)
    "WORKING_COPY": "y",             # usa o livro que já baixamos (a versão ARM64 oficial do 12.4)
    "BOOK": book,
    "BUILD_CHROOT": "y",             # do jeito do livro: capítulo 7 em diante dentro do chroot
    "LUSER": "lfs", "LGROUP": "lfs",
    "BUILDDIR": builddir,
    "GETPKG": "y", "SRC_ARCHIVE": sources, "RETRYSRCDOWNLOAD": "y", "DOWNLOADTIMEOUT": "120",
    "RUNMAKE": "n",                  # nós rodamos o make, em etapas (cada etapa do GitHub tem no máximo 6 h)
    "ALL_CORES": "y",
    "CONFIG_TESTS": "n",             # sem as baterias de testes (economiza horas; o livro marca quais são)
    "STRIP": "y",
    "NO_PROGRESS_BAR": "y",
    "CONFIG_BUILD_KERNEL": "y", "CONFIG": kconfig,
    "TIMEZONE": "America/Sao_Paulo",
    "LANG": "pt_BR.UTF-8",
    "PAGE_A4": "y",
    "HOSTNAME": "escorpiao",
    "KEYMAP": "br-abnt2",
    "REPORT": "y",
}
for name, val in ESCOLHAS.items():
    sym = k.syms.get(name)
    if sym is None:
        sys.exit("opção desconhecida no jhalfs: " + name)
    if not sym.set_value(val):
        sys.exit("não consegui marcar %s=%s" % (name, val))
k.write_config(os.path.join(jh, "configuration"))
for name, val in ESCOLHAS.items():
    got = k.syms[name].str_value
    if got != val:
        sys.exit("a opção %s ficou %r (queria %r) — dependência não atendida" % (name, got, val))
print("configuração do jhalfs gravada")
