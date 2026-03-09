SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

IMAGE ?= terminal-setup-test
CONTAINER ?= terminal-setup-test

.PHONY: help chmod setup plugins theme docker-build docker-run docker-run-detached docker-exec docker-stop docker-rm docker-logs

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; print "Available targets:"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

chmod: ## Make all setup scripts executable
	chmod +x scripts/setup.sh scripts/plugins.sh scripts/theme.sh

setup: chmod ## Run full machine setup
	./scripts/setup.sh

plugins: chmod ## Install/update Oh My Zsh plugins only
	./scripts/plugins.sh

theme: chmod ## Install/update Powerlevel10k and link .p10k.zsh
	./scripts/theme.sh

docker-build: ## Build Ubuntu test image
	docker build -t $(IMAGE) .

docker-run: ## Run temporary interactive test container
	docker run --rm -it --name $(CONTAINER) $(IMAGE)

docker-run-detached: ## Run persistent background test container
	docker run -d --name $(CONTAINER) $(IMAGE) sleep infinity

docker-exec: ## Open bash inside running test container
	docker exec -it $(CONTAINER) bash

docker-stop: ## Stop persistent test container
	docker stop $(CONTAINER)

docker-rm: ## Remove persistent test container
	docker rm -f $(CONTAINER)

docker-logs: ## Show logs from persistent test container
	docker logs $(CONTAINER)
