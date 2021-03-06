#!/bin/bash -ex
eval `opam config env`
rm -rf k
mkdir -p k/lib/java
mv ocaml-backend-*.jar k/lib/java
tar xvf k-distribution-*.tar.gz
rm -rf k-distribution-*.tar.gz
export PATH=$PATH:`pwd`/k/bin
cd c-semantics

kserver > kserver.log 2>&1 &
make -j2 fast
set +e
make -j12 -k check
RESULT=$?
set -e
test $RESULT -eq 0
