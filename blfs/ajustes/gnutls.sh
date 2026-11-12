#!/bin/bash
# Conserto do script do gnutls antes de compilar.
# O gnutls exige libtasn1 e libunistring e, do jeito do livro, um armazém de certificados via p11-kit. No nível 1 de
# dependências essas peças às vezes entram DEPOIS do gnutls (ordem errada) e ele não as acha. Para não depender da
# ordem, uso as cópias que o próprio gnutls traz embutidas (--with-included-*) e troco o armazém para o arquivo de
# certificados que o make-ca já instalou (ca-bundle.crt), dispensando o p11-kit.
s=$1
grep -q -- '--with-included-unistring' "$s" && exit 0   # já ajustado (pode rodar de novo no resume)
# armazém de certificados em arquivo (não precisa de p11-kit)
sed -i -E 's#--with-default-trust-store-pkcs11=("pkcs11:"|[^ ]+)#--with-default-trust-store-file=/etc/pki/tls/certs/ca-bundle.crt#g' "$s"
# usa as libs embutidas e desliga o p11-kit
sed -i 's#\./configure #./configure --with-included-libtasn1 --with-included-unistring --without-p11-kit #' "$s"
