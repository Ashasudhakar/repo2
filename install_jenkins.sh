#!/bin/bash
#################### Installing tools ####################
sudo yum -y update
sleep 10

echo "Install Java JDK 8"
sudo yum remove -y java
sudo yum install -y java-1.8.0-openjdk-devel
sleep 10

echo "Install git"
sudo yum install -y git jq
sleep 10

echo "Install Docker engine"
sudo yum update -y
sudo yum install docker -v 19.03.13-ce -y
sudo chkconfig docker on
sleep 10

echo "Install Jenkins"
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum -y update
sleep 10
sudo yum install -y jenkins-2.346.3
sudo usermod -a -G docker jenkins
sudo chkconfig jenkins on

sudo service docker start
sudo service jenkins start
sleep 60

ipaddr=$(hostname -I | awk '{print $1}')
# Install required jenkins plugins
sudo wget http://$ipaddr:8080/jnlpJars/jenkins-cli.jar

passwd=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
custom_user="ravi"
custom_pass="ravi123"

echo "jenkins.model.Jenkins.instance.securityRealm.createAccount(\"$custom_user\", \"$custom_pass\")" | sudo java -jar jenkins-cli.jar -auth admin:$passwd -s http://$ipaddr:8080/ groovy =

################## Install Jenkins Plugins ##################
sudo java -jar jenkins-cli.jar -auth admin:$passwd -s http://$ipaddr:8080 install-plugin amazon-ecr:1.6 \
                                                                                        cloudbees-bitbucket-branch-source:2.9.7 \
                                                                                        bitbucket:1.1.27 \
                                                                                        command-launcher:1.5 \
                                                                                        docker-workflow:1.26 \
                                                                                        docker-plugin:1.2.2 \
                                                                                        generic-webhook-trigger:1.72 \
                                                                                        jdk-tool:1.5 \
                                                                                        workflow-aggregator:2.6 \
                                                                                        ws-cleanup:0.39 \
                                                                                        file-parameters:264.v1733d9b_2a_380 \
                                                                                        ansicolor:1.0.2

# Disable initial setup in jenkins
sudo sed -i s/'JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true"'/'JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"'/g /etc/sysconfig/jenkins
sudo service jenkins restart
sleep 30