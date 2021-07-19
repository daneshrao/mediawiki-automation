#cloud-boothook
#!/bin/bash

# updates and installations
sudo yum update -y 
sudo yum -y install epel-release
sudo yum -y install python3-pip
sudo yum -y install python3-devel
sudo yum -y groupinstall 'development tools'
sudo pip3 install --upgrade pip
sudo yum install -y unzip

# Terraform Installation
sudo wget https://releases.hashicorp.com/terraform/0.12.2/terraform_0.12.2_linux_amd64.zip
sudo mkdir /bin/terraform
sudo unzip ./terraform_0.12.2_linux_amd64.zip -d /usr/local/bin/
export PATH=$PATH:/bin/terraform

#AWS CLI Installation
sudo yum install awscli -y
sudo pip3 install awscli --upgrade

#Ansible Installation
sudo yum -y install ansible

# setup-ansible-user
# create ansible user for Ansible automation and configuration management.
getentUser=$(/usr/bin/getent passwd ansible)
if [ -z "$getentUser" ]
then
  sudo echo "User ansible does not exist.  Will Add..."
  sudo /usr/sbin/groupadd -g 2002 ansible
  sudo /usr/sbin/useradd -u 2002 -g 2002 -c "Ansible Automation Account" -s /bin/bash -m -d /home/ansible ansible
sudo echo "ansible:ansible789root" | /usr/sbin/chpasswd
mkdir -p /home/ansible/.ssh
fi

# setup ssh authorization keys for Ansible access 
echo "setting up ssh authorization keys..."
sudo cat << 'EOF' >> /home/ansible/.ssh/authorized_keys
"Your authorized key"
EOF
sudo chown -R ansible:ansible /home/ansible/.ssh 
sudo chmod 700 /home/ansible/.ssh
# setup sudo access for Ansible
if [ ! -s /etc/sudoers.d/ansible ]
then
sudo echo "User ansible sudoers does not exist.  Will Add..."
sudo cat << 'EOF' > /etc/sudoers.d/ansible
User_Alias ANSIBLE_AUTOMATION = ansible
Defaults:ANSIBLE_AUTOMATION !requiretty
ANSIBLE_AUTOMATION ALL=(ALL) NOPASSWD: ALL
EOF
sudo chmod 400 /etc/sudoers.d/ansible
fi
