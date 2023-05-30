-include .env

DOCKER_COMPOSE = docker compose
EXEC = $(DOCKER_COMPOSE) exec -T
EXEC_PHP = $(EXEC) php-fpm
SYMFONY = $(EXEC_PHP) php bin/console
COMPOSER = $(EXEC_PHP) composer

##
## -------
## Project
## -------
##

build: docker-compose.override.yaml
	$(DOCKER_COMPOSE) build

start: ## Start the project
start: docker-compose.override.yaml
	$(DOCKER_COMPOSE) up -d --remove-orphans --force-recreate

install: ## Install and start the project
install: build start vendor

stop: ## Stop the project
	$(DOCKER_COMPOSE) stop

kill:
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

reset: ## Stop and start a fresh install of the project
reset: kill install

clean: ## Stop the project and remove generated files
clean: kill
	rm -rf vendor

.PHONY: build start install stop kill reset clean

##
## -----
## Utils
## -----
##

vendor: ## Install dependencies
vendor: composer.lock .env.local
	$(COMPOSER) install

.PHONY: vendor

docker-compose.override.yaml: docker-compose.override.yaml.dist
	@if [ -f docker-compose.override.yaml ]; \
	then\
		echo 'The "docker-compose.override.yaml.dist" file has been updated, you may want to update "docker-compose.override.yaml" accordingly.';\
        touch docker-compose.override.yaml;\
        exit 1;\
	else\
		echo 'Created "docker-compose.override.yaml", ensure it fits your needs and rerun the command.';\
        cp docker-compose.override.yaml.dist docker-compose.override.yaml;\
        exit 1;\
	fi

.env.local: .env
	@if [ -f .env.local ]; \
	then\
		echo 'The ".env" file has been updated, you may want to update ".env.local" accordingly.';\
		touch .env.local;\
		exit 1;\
	else\
		echo cp .env .env.local;\
		cp .env .env.local;\
	fi

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(word 1,$(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help
