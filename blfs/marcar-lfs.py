#!/usr/bin/env python3
"""Diz para a ferramenta do BLFS que todos os pacotes do LFS já estão instalados (cria o instpkg.xml) — e, se vier
uma pasta de scripts de uma etapa anterior do BLFS, também os pacotes dela (assim a etapa seguinte não repete nada).
Uso: marcar-lfs.py <blfs_root>/packages.xml <pasta-de-acompanhamento>/instpkg.xml <blfs_root>/packdesc.dtd [scripts-da-etapa-anterior]"""
import sys
import xml.etree.ElementTree as ET

import os
pk, out, dtd = sys.argv[1:4]
root = ET.parse(pk).getroot()
lfs = root.find("./list[@id='lfs']")
pkgs = [(p.findtext("name"), p.findtext("version")) for p in lfs.iter("package") if p.findtext("version")]
if len(sys.argv) > 4:                       # os pacotes da etapa anterior (nomes vêm dos scripts: 0011-z-git → git)
    antes = {f.split("-z-", 1)[1] for f in os.listdir(sys.argv[4]) if "-z-" in f}
    vers = {p.findtext("name"): p.findtext("version") for p in root.iter("package")}
    pkgs += [(n, vers[n]) for n in sorted(antes) if vers.get(n)]
with open(out, "w", encoding="ISO-8859-1") as f:
    f.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n<!DOCTYPE sublist SYSTEM "%s">\n<sublist>\n  <name>Installed</name>\n' % dtd)
    for n, v in pkgs:
        f.write("  <package><name>%s</name><version>%s</version></package>\n" % (n, v))
    f.write("</sublist>\n")
print("%d pacotes do LFS marcados como instalados" % len(pkgs))
