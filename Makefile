# tools
TERRAFORM         ?= $(shell which terraform)
KUBECTL ?= $(shell which kubectl)
MAKE ?= $(shell which make)
AWS ?= $(shell which aws)
TFLINT ?= $(shell which tflint)
TFSEC ?= $(shell which tfsec)
TFENV ?= $(shell which tfenv)

# dirs
SRC_DIR ?= $(shell git rev-parse --show-toplevel)

# prod
AWS_PROFILE ?= "samuel"
SSH_KEY_PATH ?= $(shell $(TERRAFORM) output -raw ssh_private_key_path)
INSTANCE_PUBLIC_IP ?= $(shell $(TERRAFORM) output -raw instance_ip)

IMPORT_RESOURCE_PATH ?= $(shell IFS= read -p ResourcePath: pwd && echo "$$pwd")
IMPORT_RESOURCE_ID ?= $(shell IFS= read -p ResourceID: pwd && echo "$$pwd")

.PHONY: login
login:
	$(AWS) sso login --profile $(AWS_PROFILE)

.PHONY: install
install:
	$(TFENV) install && $(TFENV) use

.PHONY: apply
apply:
	cd $(SRC_DIR) && TF_VAR_aws_profile=$(AWS_PROFILE) $(TERRAFORM) apply

.PHONY: init
init:
	cd $(SRC_DIR) && $(TERRAFORM) init --backend-config profile=$(AWS_PROFILE) -upgrade

.PHONY: lint
lint:
	cd $(SRC_DIR) && $(TERRAFORM) fmt --recursive
	cd $(SRC_DIR) && $(TERRAFORM) validate
	cd $(SRC_DIR) && $(TFLINT) --init  && $(TFLINT)
	cd $(SRC_DIR) && $(TFSEC)


.PHONY: import
import:
	cd $(SRC_DIR) && TF_VAR_aws_profile=$(AWS_PROFILE) $(TERRAFORM) import $(IMPORT_RESOURCE_PATH) $(IMPORT_RESOURCE_ID)

.PHONY: ssh
ssh:
	ssh -i $(SSH_KEY_PATH) opc@$(INSTANCE_PUBLIC_IP)
