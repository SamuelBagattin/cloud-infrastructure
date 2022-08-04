# tools
TERRAFORM         ?= $(shell which terraform)
KUBECTL ?= $(shell which kubectl)
MAKE ?= $(shell which make)
AWS ?= $(shell which aws)
TFLINT ?= $(shell which tflint)
TFSEC ?= $(shell which tfsec)

# dirs
SRC_DIR ?= $(shell git rev-parse --show-toplevel)

# prod
TFVARS ?= $(SRC_DIR)/prod.tfvars
AWS_PROFILE ?= "samuel"
SSH_KEY_PATH ?= $(shell $(TERRAFORM) output -raw ssh_private_key_path)
INSTANCE_PUBLIC_IP ?= $(shell $(TERRAFORM) output -raw instance_ip)

IMPORT_RESOURCE_PATH ?= $(shell IFS= read -p ResourcePath: pwd && echo "$$pwd")
IMPORT_RESOURCE_ID ?= $(shell IFS= read -p ResourceID: pwd && echo "$$pwd")

.PHONY: login
login:
	$(AWS) sso login --profile $(AWS_PROFILE)

.PHONY: apply
apply:
	cd $(SRC_DIR) && TF_VAR_aws_profile=$(AWS_PROFILE) $(TERRAFORM) apply --var-file=$(TFVARS)

.PHONY: init
init:
	cd $(SRC_DIR) && $(TERRAFORM) init --backend-config profile=$(AWS_PROFILE)

.PHONY: lint
lint:
	cd $(SRC_DIR) && $(TERRAFORM) fmt --recursive
	cd $(SRC_DIR) && $(TERRAFORM) validate
	cd $(SRC_DIR) && $(TFLINT) --init  && $(TFLINT) --var-file $(TFVARS)
	cd $(SRC_DIR) && $(TFSEC) --tfvars-file $(TFVARS)


.PHONY: import
import:
	cd $(SRC_DIR) && TF_VAR_aws_profile=$(AWS_PROFILE) $(TERRAFORM) import --var-file=$(TFVARS) $(IMPORT_RESOURCE_PATH) $(IMPORT_RESOURCE_ID)

.PHONY: ssh
ssh:
	ssh -i $(SSH_KEY_PATH) opc@$(INSTANCE_PUBLIC_IP)
