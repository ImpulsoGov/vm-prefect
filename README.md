<!--
# SPDX-FileCopyrightText: 2023 ImpulsoGov <contato@impulsogov.org>
#
# SPDX-License-Identifier: MIT
-->


# Configuração de máquina virtual do Prefect

Este repositório contém os templates, arquivos de configuração e script de inicialização para subir uma máquina virtual com o orquestrador de tarefas [Prefect](https://docs.prefect.io/) do zero.

## Requisitos mínimos

Esta instalação é pensada para máquinas virtuais (VMs) da Google Cloud Engine (GCE), com capacidade mínima de 4GB de RAM e 2 vCPUs, com Debian 11 "Bullseye" instalado.

Em teoria, outras configurações devem ser suportadas com alterações mínimas em relação às instruções deste README e nos arquivos de configuração. Em especial, se for instalar em outra distribuição Linux, você deve garantir que as instruções no arquivo `setup.sh` utilizam o gerenciador de pacotes correto,
bem como garantir que o caminho da chave GPG para a instalação do Docker está corretamente indicada.

## Instalação

Para começar, você deve criar e ligar a máquina virtual que deseja utilizar. Para fazer isso no GCE, siga as instruções [neste guia](https://cloud.google.com/compute/docs/instances/create-start-instance?hl=pt-br).

O passo seguinte é garantir que os arquivos contidos neste repositório sejam transferidos para a nova máquina virtual. Caso você tenha acesso direto à máquina virtual (por exemplo, por meio de um terminal no navegador), você pode fazer isso com um comando `git clone` diretamente a partir do terminal remoto. Caso contrário, você deve estabelecer uma conexão  SSH/SCP entre o seu terminal local e a VM para transferir os arquivos.

### Baixar os arquivos necessários com `git clone`

Para baixar os arquivos diretamente da VM, rode o seguinte comando no seu terminal (a VM deve ter o git instalado, o que normalmente já vem de fábrica; caso contrário, rode `sudo apt install -y git-all`):

```sh
$ git clone https://github.com/ImpulsoGov/vm-prefect.git
```

### Conectar-se e transfer os arquivos com SSH e SCP

Caso não tenha acesso ao terminal da sua VM, você deve adquirir acesso a ele por meio de um terminal remoto, usando um túnel SSH.

Para fazer isso, em primeiro lugar, garanta que as regras de firewall das suas configurações de rede permitem a entrada e saída de dados na porta 22. Na Google Cloud, você pode seguir [estas instruções](https://cloud.google.com/vpc/docs/using-firewalls?hl=pt-br#creating_firewall_rules) para configurar as regras do firewall.

Em seguida, gere um par de chaves SSH para acesso remoto à VM, e salve a chave privada em um caminho na sua máquina local. Instruções para gerar um par de chaves SSH na Google Cloud Engine podem ser encontradas [aqui](https://cloud.google.com/compute/docs/connect/create-ssh-keys?hl=pt-br).

Uma vez liberada a porta 22, você pode usar a ferramenta nativa do Linux `scp` para enviar os arquivos para a VM remotamente. Para isso, você deve obter o endereço de IP externo da instância (instruções para o GCE [aqui](https://cloud.google.com/compute/docs/instances/view-ip-address?hl=pt-br)) e substituí-lo na instrução abaixo em um terminal local:

```sh
$ git clone https://github.com/ImpulsoGov/vm-prefect.git
$ scp -i /caminho/para/chave/ssh/privada.key ./vm-prefect/* usuario@IP_EXTERNO:~
```

Alternativamente, a última linha do comando acima pode ser substituída pelo seguinte comando, caso tenha a ferramenta [gcloud](https://cloud.google.com/sdk/docs/install-sdk) instalada:

```sh
$ gcloud compute scp --recurse ./vm-prefect/* usuario@NOME_INSTANCIA:~
```

Em seguida, você deve iniciar uma sessão remota no terminal da VM para seguir com a instalação. Faça isso substituindo os trechos relevantes e executando o comando a seguir:

```sh
$ ssh -i /caminho/para/chave/ssh/privada.key usuario@IP_EXTERNO
```

## Configurar um domínio DNS

Esta instalação supõe que a API e o Frontend do Prefect serão disponibilizados em um endereço web legível. Para isso, é necessário alugar um domínio em um serviço especializado (GoDaddy, Google Domains, Cloudfare etc.).

Uma vez alugado o domínio, você deve editar os registros DNS do domínio para adicionar um registro do tipo `A` apontando o endereço web alugado para o IP público da máquina virtual onde o Prefect será instalado. Para isso, veja o [exemplo para os domínios da GoDaddy](https://br.godaddy.com/help/adicionar-um-registro-a-19238) ou consulte a documentação do serviço utilizado.

## Configurar as variáveis de ambiente

Antes executar o script de instalação, é necessário configurar algumas variáveis de ambiente que são utilizadas no processo.

Para isso, acesse o terminal remoto da máquina virtual (via terminal no navegador, SSH ou ferramenta `gcloud compute ssh`) e altere o arquivo `.env.exemplo`:

```sh
$ mv .env.exemplo .env  # renomeia o arquivo
$ nano .env  # abre o editor de textos
```

Utilize as setas do teclado para navegar no documento que será aberto em um editor de textos embutido no terminal, e altere os valores para as variáveis presentes no arquivo:

- `PREFECT_DOMINIO`: o endereço web configurado no [passo anterior](#configurar-um-domnio-dns).
- `PREFECT_ADM_EMAIL`: o e-mail para contato com o administrador do site.
- `PREFECT_API_USUARIO`: o nome de usuário a ser utilizado para acessar a API e o Frontend do Prefect.
- `PREFECT_API_SENHA`: a senha do usuário a ser utilizado para acessar a API e o Frontend do Prefect.
- `PREFECT_SENHA_SISTEMA`: a senha do usuário `prefect` que será criado na máquina virtual para gerenciar as 

Utilize as combinações de teclas `Ctrl+S` e `Ctrl+X` respectivamente para salvar e sair do documento.

## Executar o instalador

Por fim, execute o instalador:

```sh
$ chmod +x setup.sh
$ sudo /bin/bash setup.sh
```

## Verificar se os serviços estão rodando conforme o esperado

Após a instalação, rode o seguinte comando para verificar se os serviços relacionados ao Prefect foram inicializados corretamente:

```sh
$ sudo systemctl status prefect-server.service prefect-agent.service
```

Se tudo tiver ocorrido conforme o esperado, ambos os serviços aparecerão com a linha:

```
Active: active (running) since ...
```

Adicionalmente, você deve conseguir acessar o endereço web configurado para o Prefect a partir de computador, inserindo as credenciais de usuário e senha configuradas por meio das [variáveis de ambiente](#configurar-as-variveis-de-ambiente) `PREFECT_API_USUARIO` e `PREFECT_API_SENHA`.
