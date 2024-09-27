#!/bin/bash

# Instala ELK, Prometheus, Zabbix e Ansible no Ubuntu 24.04
# Script atualizado por Stenio Cordeiro de Paula - stenioc1@hotmail.com V1.0 23/09
# Script atualizado por Ulisses Caldas - tommyknockers_g@hotmail.com V1.1 25/09
# Versao customizada V1.1
# 25/09/2024

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

# Função para verificar o sucesso de cada comando
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}$1 concluído com sucesso!${NC}"
  else
    echo -e "${RED}Erro durante $1. Verifique o log para mais detalhes.${NC}"
    exit 1
  fi
}

# ------------------------------------------
# Atualizar o sistema
# ------------------------------------------
echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y
check_success "apt update/upgrade"

# ------------------------------------------
# Instalar dependências comuns
# ------------------------------------------
echo "Instalando dependências..."
sudo apt install -y curl wget gnupg2 software-properties-common lsb-release apt-transport-https
check_success "instalação de dependências"

# ------------------------------------------
# Instalar o Java (necessário para Elasticsearch e Logstash)
# ------------------------------------------
echo "Instalando Java..."
sudo apt install -y openjdk-11-jdk
check_success "instalação do Java"

# ------------------------------------------
# Instalar ELK Stack (Elasticsearch, Logstash e Kibana)
# ------------------------------------------

# ------------------------------------------
# Instalar Elasticsearch
# ------------------------------------------
echo "Instalando Elasticsearch..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo sh -c 'echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list'
sudo apt update && sudo apt install -y elasticsearch
check_success "instalação do Elasticsearch"

# ------------------------------------------
# Iniciar Elasticsearch
# ------------------------------------------
sudo systemctl enable elasticsearch --now
check_success "inicialização do Elasticsearch"

# ------------------------------------------
# Instalar Logstash
# ------------------------------------------
echo "Instalando Logstash..."
sudo apt install -y logstash
check_success "instalação do Logstash"
sudo systemctl enable logstash --now
check_success "inicialização do Logstash"

# ------------------------------------------
# Instalar Kibana
# ------------------------------------------
echo "Instalando Kibana..."
sudo apt install -y kibana
check_success "instalação do Kibana"
sudo systemctl enable kibana --now
check_success "inicialização do Kibana"

# ------------------------------------------
# Instalação do Prometheus
# ------------------------------------------

# ------------------------------------------
# Cria o usuário do Prometheus
# ------------------------------------------
sudo useradd --no-create-home --shell /bin/false prometheus

# ------------------------------------------
# Cria os diretórios para o Prometheus
# ------------------------------------------
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# ------------------------------------------
# Baixa e extrai a última versão do Prometheus
# ------------------------------------------
PROMETHEUS_VERSION="2.54.1"
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# ------------------------------------------
# Move os binários do Prometheus
# ------------------------------------------
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/

# ------------------------------------------
# Move os arquivos de configuração
# ------------------------------------------
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus.yml /etc/prometheus

# ------------------------------------------
# Ajusta permissões
# ------------------------------------------
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chmod -R 775 /etc/prometheus /var/lib/prometheus

# ------------------------------------------
# Cria o arquivo de serviço do Prometheus
# ------------------------------------------
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOL
[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOL

# ------------------------------------------
# Inicia e habilita o serviço Prometheus
# ------------------------------------------
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
check_success "instalação do Prometheus"

# ------------------------------------------
# Instalação do Grafana
# ------------------------------------------

# ------------------------------------------
# Instala dependências e adiciona o repositório do Grafana
# ------------------------------------------
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y "deb https://packages.grafana.com/oss/deb stable main"

# ------------------------------------------
# Adiciona a chave GPG do Grafana
# ------------------------------------------
sudo wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# ------------------------------------------
# Atualiza o repositório e instala o Grafana
# ------------------------------------------
sudo apt-get update -y
sudo apt-get install -y grafana

# ------------------------------------------
# Inicia e habilita o serviço Grafana
# ------------------------------------------
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
check_success "instalação do Grafana"

# ------------------------------------------
# Instalar Zabbix (Servidor + Frontend)
# ------------------------------------------

echo "Instalando Zabbix Server..."
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_7.0-2+ubuntu24.04_all.deb
sudo apt update
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent mariadb-server
check_success "instalação do Zabbix"

# ------------------------------------------
# Configurar banco de dados para Zabbix
# ------------------------------------------
sudo systemctl start mariadb
sudo mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix_password';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix_password zabbix

# ------------------------------------------
# Configurar Zabbix para usar o MySQL
# ------------------------------------------
sudo sed -i 's/# DBPassword=/DBPassword=zabbix_password/' /etc/zabbix/zabbix_server.conf
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
check_success "configuração do Zabbix"

# ------------------------------------------
# Instalar Ansible
# ------------------------------------------

echo "Instalando Ansible..."
sudo apt install -y ansible
check_success "instalação do Ansible"

# ------------------------------------------
# Verifica status dos serviços
# ------------------------------------------

sudo systemctl status elasticsearch --no-pager
sudo systemctl status logstash --no-pager
sudo systemctl status kibana --no-pager
sudo systemctl status prometheus --no-pager
sudo systemctl status grafana-server --no-pager
sudo systemctl status zabbix-server --no-pager
sudo systemctl status zabbix-agent --no-pager

echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo "Instalação concluída!"
echo "Acesse o Prometheus em http://<IP_DO_SERVIDOR>:9090"
echo "Acesse o Grafana em http://<IP_DO_SERVIDOR>:3000"
echo "Login padrão do Grafana: admin / admin"
echo "Acess o Zabbix em http://<IP_DO_SERVIDOR>/zabbix"
echo "Ansible versão instalada: $(ansible --version | head -n 1)"
echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"