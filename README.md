# Escorpião OS

Uma distribuição Linux **feita do zero**, para celulares e computadores com processador **ARM64**, seguindo o livro
**Linux From Scratch 12.4** (a edição ARM64 oficial do time do LFS) e o **Beyond Linux From Scratch 12.4**
(a área de trabalho e os programas). Ela roda dentro do app Jarvis (no celular) e também como um `.iso` (no computador).

## Pense assim

O livro LFS é uma receita de bolo gigante: ele diz, passo a passo, como fazer cada pedaço de um Linux a partir do
código-fonte — primeiro as ferramentas para cozinhar (o compilador), depois a "massa" (as bibliotecas e os programas
básicos), depois o "forno" (o kernel e o início do sistema). O BLFS é o segundo livro: a "cobertura" (a tela gráfica,
o navegador, os programas).

Quem segue a receita aqui não sou eu nem você: é o **jhalfs**, a ferramenta oficial do próprio projeto LFS, que lê o
livro e roda os comandos dele, na ordem certa. Este repositório só diz QUAIS páginas usar, e junta tudo no final.

## O que tem dentro

| Parte | De onde vem | O que é |
|---|---|---|
| Compilador e sistema básico | LFS 12.4 ARM64, capítulos 4 a 8 | GCC 15.2, glibc 2.42, binutils 2.45, bash, coreutils, Python 3.13, Perl, Vim… |
| Início do sistema | LFS, capítulos 9 e 10 | SysVinit, os scripts de início, o kernel **Linux 6.16.1** |
| Área de trabalho | BLFS 12.4 | **XFCE 4.20** com barra embaixo e botão "Iniciar" (jeito parecido com o do Windows) |
| Servidor gráfico | BLFS 12.4 (TigerVNC 1.15) | o **Xvnc**: desenha a tela e manda para o Jarvis mostrar |
| Programas | BLFS 12.4 | Firefox, Gnumeric (planilhas), Parole e mpv (vídeo e música), Ristretto (fotos), Mousepad (textos), Thunar (arquivos), Git |

## Como é construído (no GitHub, de graça)

O arquivo `.github/workflows/construir.yml` faz tudo nos computadores **ARM64** do GitHub, em etapas de até 6 horas
(o limite deles). Cada etapa guarda o que já fez e a próxima continua de onde parou:

1. `lfs/` — o jhalfs roda o livro LFS 12.4 ARM64 inteiro (`lfs/gerar-config.py` escolhe as opções; o kernel
   recebe as opções que o livro exige em `lfs/kernel-config.sh`).
2. `blfs/` — a ferramenta do jhalfs para o BLFS calcula, a partir do livro, **tudo** o que cada programa pedido em
   `blfs/desktop.txt` e `blfs/extras.txt` precisa, e em que ordem (são uns 250 pacotes). `blfs/rodar.sh` instala
   um por um dentro do sistema novo.
3. `escorpiao/` — o nome, o papel de parede e o visual.
4. `iso/` e `android/` — as entregas.

Para começar: aba **Actions › Construir o Escorpião OS › Run workflow**. Se uma etapa falhar, dá para continuar de
onde parou: rode de novo informando o número da execução em "retomar".

## As entregas (aba Releases)

- `escorpiao-os-arm64.tar.gz` — o sistema para o celular (o Jarvis baixa e instala sozinho).
- `escorpiao-os-arm64.iso` — o sistema "ao vivo" para computador/máquina virtual ARM64 com UEFI
  (ex.: QEMU `-M virt`, UTM no Mac). Usuário `root`, senha `escorpiao`. Para a área de trabalho: `startx`.
- `escorpiao-kernel-*-arm64.efi` e `config-*` — o kernel e a configuração dele.
- `libproot.so` e `libproot-loader.so` — o proot (do Termux), que deixa o sistema rodar por cima do Android sem root.
- `codigos-fonte.tar.parteNN` — todos os códigos-fonte usados (junte com `cat codigos-fonte.tar.parte* > fontes.tar`).

## No celular: por que não usa o kernel próprio?

Um app não consegue trocar o kernel do Android (isso exige root e desbloquear o aparelho). Então, no celular, o
Escorpião OS roda **por cima** do kernel do próprio Android (com o proot, como o Termux faz) — todo o resto é o
sistema que foi feito do zero aqui. O kernel próprio é usado no `.iso`.

## Licenças

Cada programa mantém a sua licença (a maioria GPL/LGPL/MIT). Os códigos-fonte de tudo estão nas entregas. Os livros
LFS/BLFS são do projeto Linux From Scratch (licença MIT para os comandos); o jhalfs também é do projeto LFS.
