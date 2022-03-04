#!/bin/bash
sudo hostnamectl set-hostname $hostname
sudo apt update;
DEBIAN_FRONTEND=noninteractive sudo apt-get -y full-upgrade;
DEBIAN_FRONTEND=noninteractive sudo apt-get -y upgrade;

DEBIAN_FRONTEND=noninteractive sudo apt autoremove -y;
DEBIAN_FRONTEND=noninteractive sudo apt autoclean -y;
DEBIAN_FRONTEND=noninteractive sudo apt install git curl -y;

sudo userdel ubuntu
sudo rm -rf /home/ubuntu

sudo sed -i 's/.*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config;
sudo sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/^#\?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config;
sudo chsh -s /bin/bash $USER;
sudo systemctl restart ssh;

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"