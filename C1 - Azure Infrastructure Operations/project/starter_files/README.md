# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

#### 1: Create tagging policy

In order to deny the creation of resources that do not have tags in Azure, you can use Azure Policy. Azure Policy is a service in Azure that allows you to create, assign, and manage policies to enforce compliance with organizational rules and standards.

```bash
az policy definition create --name "DenyIndexedResourcesWithoutTags" --display-name "All indexed resources are tagged" --description "Policy definition to deny the creation of resources that do not have tags" --rules DenyIndexedResourcesWithoutTags.json --mode indexed
```

##### Assign the policy to the azure subscription

```bash
az policy assignment create --name "tagging-policy" --display-name "Apply the policy definition to the subscription with name tagging-policy" --scope /subscriptions/<subscription> --policy /subscriptions/<subscription>/providers/Microsoft.Authorization/policyDefinitions/DenyIndexedResourcesWithoutTags
```

I first tried with a policy which checks for existence only, but this is not working for me. I had to create a policy which checks for length too.

```bash
$ az vm create --resource-group udacity --name udacity-vm --image UbuntuLTS --generate-ssh-keys --output json --verbose --admin-username udacity
```

##### Output

```bash
Selecting "uksouth" may reduce your costs. The region you've selected may cost more for the same services. You can disable this message in the future with the command "az config set core.display_region_identified=false". Learn more at https://go.microsoft.com/fwlink/?linkid=222571 
Use existing SSH public key file: /home/kram030/.ssh/id_rsa.pub
Ignite (November) 2023 onwards "az vm/vmss create" command will deploy Gen2-Trusted Launch VM by default. To know more about the default change and Trusted Launch, please visit https://aka.ms/TLaD
It is recommended to use parameter "--public-ip-sku Standard" to create new VM with Standard public IP. Please note that the default public IP used for VM creation will be changed from Basic to Standard in the future.
Consider using the "Ubuntu2204" alias. On April 30, 2023,the image deployed by the "UbuntuLTS" alias reaches its end of life. The "UbuntuLTS" will be removed with the breaking change release of Fall 2023.
{"error":{"code":"InvalidTemplateDeployment","message":"The template deployment failed with multiple errors. Please see details for more information.","details":[{"code":"RequestDisallowedByPolicy","target":"udacity-vmVNET","message":"Resource 
...
Command ran in 5.345 seconds (init: 0.366, invoke: 4.978)
```

#### 2: Packer template

The server image is created by server.json using packer.

First create azure credentials

see: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer

az ad sp create-for-rbac --role Contributor --scopes /subscriptions/<subscription_id> --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"

output:
{
  "client_id": "05038539-....",
  "client_secret": "6mt8Q~O......",
  "tenant_id": "26dcbb7e....."
}


```bash
packer build -var 'client_id=<client-id>' -var 'client_secret=<client-secret>' -var 'subscription_id=<subscription-id>' server.json
```

Output:

```bash
==> Builds finished. The artifacts of successful builds are:
--> azure-arm: Azure.ResourceManagement.VMImage:

OSType: Linux
ManagedImageResourceGroupName: udacity
ManagedImageName: UdacityPackerImage
ManagedImageId: /subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Compute/images/UdacityPackerImage
ManagedImageLocation: West Europe
```

#### 3: Terraform

Commands for provisioning with terraform:

##### Initial deployment and modifications to existing deployment

```:bash
# Initialize terraform
terraform init

# Plan and apply
terraform plan -out solution.plan
terraform apply
```

##### Destroy all resources provisioned

```bash
terraform destroy
```

##### Modify variables

Defaults are stored in variables.tf and can be changed there:
- prefix
- location
- resource_group_name
- packer_image_name
- admin_user
- admin_password
- virtual_machines_count


##### Output
The Terraform apply command outputs these values after successfully provisioning the resources:
- public_IP_Load_Balancer: Public HTTP service IP address of the load balancer in front of the webservers.

```bash
kram030@ASY-0096231875:~/nd082-Azure-Cloud-DevOps-Starter-Code/C1 - Azure Infrastructure Operations/project$ terraform apply
data.azurerm_resource_group.main: Reading...
azurerm_resource_group.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity]
data.azurerm_resource_group.main: Read complete after 0s [id=/subscriptions/<subscription>/resourceGroups/udacity]
azurerm_availability_set.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Compute/availabilitySets/udacity-c1-availability-set]
data.azurerm_image.main: Reading...
azurerm_public_ip.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/publicIPAddresses/udacity-c1-public-ip]
azurerm_virtual_network.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/virtualNetworks/udacity-c1-network]
data.azurerm_image.main: Read complete after 0s [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Compute/images/UdacityPackerImage]
azurerm_lb.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/loadBalancers/udacity-c1-load-balancer]
azurerm_subnet.internal: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/virtualNetworks/udacity-c1-network/subnets/internal]
azurerm_lb_backend_address_pool.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/loadBalancers/udacity-c1-load-balancer/backendAddressPools/udacity-c1-backend-address-pool]
azurerm_lb_probe.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/loadBalancers/udacity-c1-load-balancer/probes/udacity-c1-probe]
azurerm_network_interface.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/networkInterfaces/udacity-c1-network-interface]
azurerm_network_security_group.main[0]: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/networkSecurityGroups/udacity-c1-main-0]
azurerm_lb_rule.main: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/loadBalancers/udacity-c1-load-balancer/loadBalancingRules/udacity-c1-rule]
azurerm_network_interface_security_group_association.main[0]: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/networkInterfaces/udacity-c1-network-interface|/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/networkSecurityGroups/udacity-c1-main-0]
azurerm_linux_virtual_machine.main[0]: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Compute/virtualMachines/udacity-c1-vm-0]
azurerm_network_interface_backend_address_pool_association.main[0]: Refreshing state... [id=/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/networkInterfaces/udacity-c1-network-interface/ipConfigurations/public|/subscriptions/<subscription>/resourceGroups/udacity/providers/Microsoft.Network/loadBalancers/udacity-c1-load-balancer/backendAddressPools/udacity-c1-backend-address-pool]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

public_ip = "98.71.223.40"

```
