
COMPOSE = sudo docker compose

.PHONY: build up down restart logs ps config deploy deploy-api deploy-web rollback-api rollback-web

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
	bash scripts/deploy.sh api
	bash scripts/deploy.sh web

deploy-api:
	bash scripts/deploy.sh api

deploy-web:
	bash scripts/deploy.sh web

rollback-api:
	bash scripts/rollback.sh api

rollback-web:
	bash scripts/rollback.sh web

