#!/bin/bash

# SPDX-FileCopyrightText: 2022 ImpulsoGov <contato@impulsogov.org>
#
# SPDX-License-Identifier: MIT


# mova este arquivo para o diretório /home/prefect/
# Permita a execução dele rodando o comando 
# `chmod +x /home/prefect/server-start.sh`

main () {
  . /home/prefect/.venv/bin/activate;
  prefect server start --host 0.0.0.0;
}
main
