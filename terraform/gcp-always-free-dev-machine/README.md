
# Test Google Cloud Platform


## Prerequisites

Install Google Cloud SDK and run

    gcloud init
    gcloud auth application-default login


Navigate to https://console.developers.google.com/ API manager and
enable Google Compute Engine API for the project.


## Create environment

Check the action plan

    terraform plan


Apply the configuration

    terraform apply


## Run provisioning

Create inventory file

    echo "[dev]" > inventory.ini
    terraform output -json | jq -r '.public_ips.value | .[]' >> inventory.ini


Add host key to known hosts

    ansible-playbook ssh-keyscan.yml


Then execute playbook

    ansible-playbook deploy.yml
