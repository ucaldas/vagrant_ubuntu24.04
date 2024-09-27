Vagrant.configure("2") do |config|
  config.vm.box = "gutehall/ubuntu24-04"
  config.vm.box_version = "2024.08.30"
  # for Prometheus
  config.vm.network "forwarded_port", guest: 9090, host: 9090
  # for Gafana
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  # for MySQL
  config.vm.network "forwarded_port", guest: 3306, host: 3306
  # for ELK
  config.vm.network "forwarded_port", guest: 5601, host: 5601
  # for Zabbix and host "80"
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
  #
  config.vm.provision "shell", path: "provision.sh"
end
