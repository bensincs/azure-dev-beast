#!/usr/bin/make -f

# -------- CONFIG --------
KEY_PATH ?= ./keys/id_rsa
KEY_COMMENT ?= generated-key
KEY_TYPE ?= rsa
KEY_BITS ?= 4096
RESOURCE_GROUP ?= rg-beast
LOCATION ?= uaenorth
BICEP_FILE ?= ./main.bicep
DEPLOYMENT_NAME ?= beast-deployment
USERNAME ?= azureuser
VNET_NAME ?= vnet-beast
SUBNET_NAME ?= subnet-beast
VM_NAME ?= vm-beast

# -------- COLORS --------
YELLOW=\033[0;33m
GREEN=\033[0;32m
BLUE=\033[1;34m
NC=\033[0m

# -------- AUTO HELP --------
.PHONY: help
help:
	@echo ""
	@echo "${BLUE}Available targets:${NC}"
	@grep -E '^([a-zA-Z0-9_-]+):.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2}'
	@echo ""

# -------- SSH KEY GENERATION --------
keys: ## Generate a public/private key pair at defined path
	@echo "${GREEN}Generating SSH key pair at ${KEY_PATH}...${NC}"
	@mkdir -p $(dir $(KEY_PATH))
	@ssh-keygen -t $(KEY_TYPE) -b $(KEY_BITS) -C "$(KEY_COMMENT)" -f $(KEY_PATH) -N ""
	@echo "${GREEN}Key generation completed:${NC}"
	@echo "  🔑 Private key: $(KEY_PATH)"
	@echo "  🗝  Public key : $(KEY_PATH).pub"

# -------- AZURE RESOURCE GROUP --------
.PHONY: rg
rg: ## Create the Azure resource group
	@echo "${GREEN}Creating resource group: $(RESOURCE_GROUP) in $(LOCATION)...${NC}"
	az group create --name $(RESOURCE_GROUP) --location $(LOCATION)

# -------- DEPLOY BICEP INFRASTRUCTURE --------
.PHONY: infra
infra: rg keys ## Deploy infrastructure using the Bicep file
	@echo "${GREEN}Deploying Bicep file: $(BICEP_FILE) to $(RESOURCE_GROUP)...${NC}"
	az deployment group create \
		--name $(DEPLOYMENT_NAME) \
		--resource-group $(RESOURCE_GROUP) \
		--parameters sshPublicKey="$(shell cat $(KEY_PATH).pub)" \
		--parameters username=$(USERNAME) \
		--parameters vmName=$(VM_NAME) \
		--parameters vnetName=$(VNET_NAME) \
		--parameters subnetName=$(SUBNET_NAME) \
		--template-file $(BICEP_FILE)

# -------- CONFIGURE VM --------
.PHONY: configure
configure: infra ## Runs the ./configure.sh script on the vm
	@echo "${GREEN}Running configuration script on the VM...${NC}"
	@scp -i $(KEY_PATH) ./configure.sh $(USERNAME)@$(shell az vm show -d -g $(RESOURCE_GROUP) -n $(VM_NAME) --query publicIps -o tsv):/tmp/configure.sh
	@ssh -i $(KEY_PATH) $(USERNAME)@$(shell az vm show -d -g $(RESOURCE_GROUP) -n $(VM_NAME) --query publicIps -o tsv) 'bash /tmp/configure.sh'
	@echo "${GREEN}Configuration script has been executed.${NC}"

# -------- ADD TO SSH CONFIG --------
.PHONY: ssh-config
ssh-config: infra ## Add the VM to the SSH config file
	@echo "${GREEN}Adding VM to SSH config...${NC}"
	@echo "" >> ~/.ssh/config
	@echo "Host $(VM_NAME)" >> ~/.ssh/config
	@echo "  HostName $(shell az vm show -d -g $(RESOURCE_GROUP) -n $(VM_NAME) --query publicIps -o tsv)" >> ~/.ssh/config
	@echo "  User $(USERNAME)" >> ~/.ssh/config
	@echo "  IdentityFile $(realpath $(KEY_PATH))" >> ~/.ssh/config
	@echo "${GREEN}VM added to SSH config.${NC}"

# -------- CLEANUP --------
.PHONY: clean
clean: ## Remove the generated key files
	@echo "${YELLOW}Cleaning up key files...${NC}"
	@rm -f $(KEY_PATH) $(KEY_PATH).pub
	@echo "${GREEN}Done.${NC}"

	@echo "${YELLOW}Removing VM from SSH config...${NC}"
	@sed -i '' '/Host $(VM_NAME)/,/^$$/d' ~/.ssh/config
	@echo "${GREEN}Done.${NC}"

# -------- DESTROY INFRASTRUCTURE --------
.PHONY: destroy
destroy: ## Destroy the Azure resource group
	@echo "${YELLOW}Destroying resource group: $(RESOURCE_GROUP)...${NC}"
	@az group delete --name $(RESOURCE_GROUP) --yes
	@echo "${GREEN}Resource group $(RESOURCE_GROUP) has been destroyed.${NC}"