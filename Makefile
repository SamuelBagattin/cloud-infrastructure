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

AWS_MFA_SERIAL_NUMBER ?= $(shell aws iam list-mfa-devices --profile $(AWS_PROFILE) | jq -r '.MFADevices[0].SerialNumber')
SESSION_TOKEN ?= $(shell IFS= read -s  -p Password: pwd && aws sts --profile $(AWS_PROFILE) get-session-token --serial-number $(AWS_MFA_SERIAL_NUMBER) --token-code $$pwd | jq -r '.Credentials.SessionToken')
IMPORT_RESOURCE_PATH ?= $(shell IFS= read -p ResourcePath: pwd && echo "$$pwd")
IMPORT_RESOURCE_ID ?= $(shell IFS= read -p ResourceID: pwd && echo "$$pwd")

.PHONY: apply
apply:
	cd $(SRC_DIR) && TF_VAR_aws_session_token=$(SESSION_TOKEN) AWS_PROFILE=$(AWS_PROFILE) $(TERRAFORM) apply --var-file=$(TFVARS)

.PHONY: init
init:
	cd $(SRC_DIR) && $(TERRAFORM) init --backend-config profile=$(AWS_PROFILE)

.PHONY: lint
lint:
	cd $(SRC_DIR) && $(TERRAFORM) validate
	cd $(SRC_DIR) && $(TFLINT) --init  && $(TFLINT) --var-file $(TFVARS)
	cd $(SRC_DIR) && $(TFSEC) --tfvars-file $(TFVARS)


.PHONY: import
import:
	cd $(SRC_DIR) && TF_VAR_aws_session_token=$(SESSION_TOKEN) AWS_PROFILE=$(AWS_PROFILE) $(TERRAFORM) import --var-file=$(TFVARS) $(IMPORT_RESOURCE_PATH) $(IMPORT_RESOURCE_ID)


