#!/bin/bash
# update system
dnf update -y

# set Hostname
hostnamectl set-hostname jenkins-server

# Install Git
dnf install git -y

# Install Java 17 (Amazon Corretto or OpenJDK)
dnf install java-17-amazon-corretto-devel -y || dnf install java-17-openjdk-devel -y

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade -y
dnf install jenkins -y
systemctl enable jenkins
systemctl start jenkins

# Install Docker
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io -y
systemctl enable --now docker

# Add users to docker group
usermod -aG docker opc
usermod -aG docker jenkins

# Configure Docker to expose TCP socket for Jenkins agents
cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/dockerd -H tcp://127.0.0.1:2376 -H unix:///var/run/docker.sock|' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker
systemctl restart jenkins

# Install Trivy
dnf install wget -y
wget https://github.com/aquasecurity/trivy/releases/download/v0.31.3/trivy_0.31.3_Linux-64bit.rpm
rpm -ivh trivy_0.31.3_Linux-64bit.rpm