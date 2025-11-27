# Makefile for DXSpider Helm Chart
# Provides common operations for development and testing

# Variables
CHART_NAME := dxspider
NAMESPACE := dxspider
RELEASE_NAME := my-dxspider
HELM := helm
KUBECTL := kubectl

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m

.PHONY: help
help: ## Show this help message
	@echo "$(COLOR_BOLD)DXSpider Helm Chart - Available Commands:$(COLOR_RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_GREEN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ""

.PHONY: lint
lint: ## Lint the Helm chart
	@echo "$(COLOR_BLUE)Linting Helm chart...$(COLOR_RESET)"
	$(HELM) lint .

.PHONY: template
template: ## Render chart templates
	@echo "$(COLOR_BLUE)Rendering templates...$(COLOR_RESET)"
	$(HELM) template $(RELEASE_NAME) . --namespace $(NAMESPACE)

.PHONY: template-debug
template-debug: ## Render chart templates with debug output
	@echo "$(COLOR_BLUE)Rendering templates with debug...$(COLOR_RESET)"
	$(HELM) template $(RELEASE_NAME) . --namespace $(NAMESPACE) --debug

.PHONY: template-prod
template-prod: ## Render chart templates with production values
	@echo "$(COLOR_BLUE)Rendering templates with production values...$(COLOR_RESET)"
	$(HELM) template $(RELEASE_NAME) . --namespace $(NAMESPACE) -f values-production.yaml

.PHONY: dry-run
dry-run: ## Perform a dry-run installation
	@echo "$(COLOR_BLUE)Performing dry-run installation...$(COLOR_RESET)"
	$(HELM) install $(RELEASE_NAME) . --namespace $(NAMESPACE) --dry-run --debug

.PHONY: install
install: ## Install the chart
	@echo "$(COLOR_BLUE)Installing chart...$(COLOR_RESET)"
	$(KUBECTL) create namespace $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(HELM) install $(RELEASE_NAME) . --namespace $(NAMESPACE)

.PHONY: install-prod
install-prod: ## Install the chart with production values
	@echo "$(COLOR_BLUE)Installing chart with production values...$(COLOR_RESET)"
	$(KUBECTL) create namespace $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(HELM) install $(RELEASE_NAME) . --namespace $(NAMESPACE) -f values-production.yaml

.PHONY: upgrade
upgrade: ## Upgrade the release
	@echo "$(COLOR_BLUE)Upgrading release...$(COLOR_RESET)"
	$(HELM) upgrade $(RELEASE_NAME) . --namespace $(NAMESPACE)

.PHONY: upgrade-prod
upgrade-prod: ## Upgrade the release with production values
	@echo "$(COLOR_BLUE)Upgrading release with production values...$(COLOR_RESET)"
	$(HELM) upgrade $(RELEASE_NAME) . --namespace $(NAMESPACE) -f values-production.yaml

.PHONY: uninstall
uninstall: ## Uninstall the release
	@echo "$(COLOR_YELLOW)Uninstalling release...$(COLOR_RESET)"
	$(HELM) uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: status
status: ## Show release status
	@echo "$(COLOR_BLUE)Release status:$(COLOR_RESET)"
	$(HELM) status $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: history
history: ## Show release history
	@echo "$(COLOR_BLUE)Release history:$(COLOR_RESET)"
	$(HELM) history $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: get-values
get-values: ## Get values of installed release
	@echo "$(COLOR_BLUE)Installed values:$(COLOR_RESET)"
	$(HELM) get values $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: get-manifest
get-manifest: ## Get manifest of installed release
	@echo "$(COLOR_BLUE)Installed manifest:$(COLOR_RESET)"
	$(HELM) get manifest $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: test
test: lint template ## Run all tests (lint and template)
	@echo "$(COLOR_GREEN)All tests passed!$(COLOR_RESET)"

.PHONY: package
package: ## Package the chart
	@echo "$(COLOR_BLUE)Packaging chart...$(COLOR_RESET)"
	$(HELM) package .

.PHONY: package-sign
package-sign: ## Package and sign the chart
	@echo "$(COLOR_BLUE)Packaging and signing chart...$(COLOR_RESET)"
	$(HELM) package --sign .

.PHONY: verify
verify: ## Verify a packaged chart
	@echo "$(COLOR_BLUE)Verifying packaged chart...$(COLOR_RESET)"
	$(HELM) verify $(CHART_NAME)-*.tgz

.PHONY: docs
docs: ## Generate documentation
	@echo "$(COLOR_BLUE)Generating documentation...$(COLOR_RESET)"
	@echo "README.md already exists. Use helm-docs to auto-generate if needed."

.PHONY: clean
clean: ## Clean up packaged charts
	@echo "$(COLOR_YELLOW)Cleaning up...$(COLOR_RESET)"
	rm -f $(CHART_NAME)-*.tgz $(CHART_NAME)-*.tgz.prov

.PHONY: logs
logs: ## Show DXSpider logs
	@echo "$(COLOR_BLUE)Showing logs...$(COLOR_RESET)"
	$(KUBECTL) logs -f --namespace $(NAMESPACE) -l app.kubernetes.io/name=$(CHART_NAME)

.PHONY: exec
exec: ## Execute shell in DXSpider pod
	@echo "$(COLOR_BLUE)Executing shell in pod...$(COLOR_RESET)"
	$(KUBECTL) exec -it --namespace $(NAMESPACE) $(RELEASE_NAME)-0 -- /bin/sh

.PHONY: port-forward-telnet
port-forward-telnet: ## Port forward telnet port
	@echo "$(COLOR_BLUE)Port forwarding telnet (7300)...$(COLOR_RESET)"
	@echo "Connect with: telnet localhost 7300"
	$(KUBECTL) port-forward --namespace $(NAMESPACE) svc/$(RELEASE_NAME) 7300:7300

.PHONY: port-forward-console
port-forward-console: ## Port forward web console port
	@echo "$(COLOR_BLUE)Port forwarding console (8050)...$(COLOR_RESET)"
	@echo "Access at: http://localhost:8050"
	$(KUBECTL) port-forward --namespace $(NAMESPACE) svc/$(RELEASE_NAME) 8050:8050

.PHONY: get-password
get-password: ## Get sysop password
	@echo "$(COLOR_BLUE)Sysop password:$(COLOR_RESET)"
	@$(KUBECTL) get secret --namespace $(NAMESPACE) $(RELEASE_NAME)-secret -o jsonpath="{.data.sysop-password}" | base64 --decode
	@echo ""

.PHONY: watch
watch: ## Watch pod status
	@echo "$(COLOR_BLUE)Watching pods...$(COLOR_RESET)"
	watch $(KUBECTL) get pods --namespace $(NAMESPACE) -l app.kubernetes.io/name=$(CHART_NAME)

.PHONY: describe-pod
describe-pod: ## Describe DXSpider pod
	@echo "$(COLOR_BLUE)Describing pod...$(COLOR_RESET)"
	$(KUBECTL) describe pod --namespace $(NAMESPACE) -l app.kubernetes.io/name=$(CHART_NAME)

.PHONY: get-pvc
get-pvc: ## Get PersistentVolumeClaims
	@echo "$(COLOR_BLUE)PersistentVolumeClaims:$(COLOR_RESET)"
	$(KUBECTL) get pvc --namespace $(NAMESPACE)

.PHONY: delete-namespace
delete-namespace: ## Delete namespace and all resources
	@echo "$(COLOR_YELLOW)WARNING: This will delete ALL resources in the $(NAMESPACE) namespace!$(COLOR_RESET)"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read dummy
	$(KUBECTL) delete namespace $(NAMESPACE)

.DEFAULT_GOAL := help
