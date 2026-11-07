
COMPOSE = sudo docker compose

.PHONY: build up down restart logs ps deploy config deploy-api deploy-web

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f --tail=100

ps:
	$(COMPOSE) ps

config:
	$(COMPOSE) config

deploy:
	$(COMPOSE) up -d --build

deploy-api:
	$(COMPOSE) up -d --no-deps --build api

deploy-web:
	$(COMPOSE) up -d --no-deps --build web
