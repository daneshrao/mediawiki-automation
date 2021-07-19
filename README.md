# mediawiki Deployment
Tools Leveraged:
  Terraform 0.12
  Ansible 2.6
  Shell script
  
Platform Tested:
  AWS

Infra overview:

![image](https://user-images.githubusercontent.com/38915899/126106286-88050d3b-3912-4223-9593-ebbdca95f6ac.png)



Usage:

  Clone project:
    git clone "project name"
    
  Steps:
    Add the appropriate vars to connect with the AWS infra
    change the variables in the variables.tf
    change the deployment url in the ansible vars
    terraform init
    terraform apply
    ansible-playbook -u "remoteuser" main.yml
