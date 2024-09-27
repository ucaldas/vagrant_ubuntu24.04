Monstar o Laboratório, Instalado o vagrant 2.4.1 no windows 11 com virtualbox 7.0.20.
Executar o gitclone e na pasta onde estiver o Vagranfile executar:
  # vagrant up

Isso deve baixar a imagem do Ubuntu e fazer  instalação automaticamente.

A  configuração está redirecionando as portas internas para o Localhost

Caso não tiver provisionado, efetuar esse comando:
  # vagrant provision

Para entrar no servidor:
  # vagrant ssh
