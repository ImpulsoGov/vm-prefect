#!/bin/bash

# SPDX-FileCopyrightText: 2023 ImpulsoGov <contato@impulsogov.org>
#
# SPDX-License-Identifier: MIT


# mova este arquivo para o diretório /home/prefect/
# Permita a execução dele rodando o comando `chmod +x /home/prefect/agent-start.sh`

main () {
  . /home/prefect/.venv/bin/activate;
  prefect agent start -q impulso-previne -q saude-mental -q geral;
}
main
