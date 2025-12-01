# Default values
MODE ?= dev
SERVICE ?= backend
ARGS ?=

# Docker compose file selection
ifeq ($(MODE),prod)
    COMPOSE_FILE = docker/compose.production.yaml
else
    COMPOSE_FILE = docker/compose.development.yaml
endif

# Docker Services
up:
	docker-compose -f $(COMPOSE_FILE) --env-file .env up $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

down:
	docker-compose -f $(COMPOSE_FILE) --env-file .env down $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

build:
	docker-compose -f $(COMPOSE_FILE) --env-file .env build $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

logs:
	docker-compose -f $(COMPOSE_FILE) --env-file .env logs $(ARGS) $(SERVICE)

restart:
	docker-compose -f $(COMPOSE_FILE) --env-file .env restart $(filter-out $@,$(MAKECMDGOALS))

shell:
	docker-compose -f $(COMPOSE_FILE) --env-file .env exec $(SERVICE) sh

ps:
	docker-compose -f $(COMPOSE_FILE) --env-file .env ps

# Development Aliases
dev-up:
	$(MAKE) up MODE=dev ARGS="--build -d"

dev-down:
	$(MAKE) down MODE=dev

dev-build:
	$(MAKE) build MODE=dev

dev-logs:
	$(MAKE) logs MODE=dev

dev-restart:
	$(MAKE) restart MODE=dev

dev-shell:
	$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	$(MAKE) ps MODE=dev

backend-shell:
	$(MAKE) shell SERVICE=backend

gateway-shell:
	$(MAKE) shell SERVICE=gateway

mongo-shell:
	docker-compose -f $(COMPOSE_FILE) --env-file .env exec mongo mongosh -u admin -p password123 --authenticationDatabase admin

# Production Aliases
prod-up:
	$(MAKE) up MODE=prod ARGS="--build -d"

prod-down:
	$(MAKE) down MODE=prod

prod-build:
	$(MAKE) build MODE=prod

prod-logs:
	$(MAKE) logs MODE=prod

prod-restart:
	$(MAKE) restart MODE=prod

# Backend Commands
backend-build:
	cd backend && npm run build

backend-install:
	cd backend && npm install

backend-type-check:
	cd backend && npm run type-check

backend-dev:
	cd backend && npm run dev

# Database Commands
db-reset:
	docker-compose -f $(COMPOSE_FILE) --env-file .env exec mongo mongosh -u admin -p password123 --authenticationDatabase admin --eval "db.getSiblingDB('ecommerce').dropDatabase()"

db-backup:
	@mkdir -p ./backup
	docker-compose -f $(COMPOSE_FILE) --env-file .env exec -T mongo mongodump -u admin -p password123 --authenticationDatabase admin --db ecommerce --archive > ./backup/db-backup-$$(date +%Y%m%d-%H%M%S).archive
	@echo "Backup saved to ./backup/"

db-restore:
	@if [ -z "$(FILE)" ]; then echo "Usage: make db-restore FILE=backup/db-backup-XXXXXX.archive"; exit 1; fi
	docker-compose -f $(COMPOSE_FILE) --env-file .env exec -T mongo mongorestore -u admin -p password123 --authenticationDatabase admin --archive < $(FILE)
	@echo "Database restored from $(FILE)"

db-list-volumes:
	docker volume ls | grep mongo

# Cleanup Commands
clean:
	docker-compose -f docker/compose.development.yaml --env-file .env down --remove-orphans
	docker-compose -f docker/compose.production.yaml --env-file .env down --remove-orphans
	docker network prune -f

clean-all:
	$(MAKE) clean
	docker system prune -af --volumes

clean-volumes:
	docker volume prune -f

# Utilities
status:
	$(MAKE) ps

health:
	@echo "Checking service health..."
	@curl -f http://localhost:5921/health || echo "Gateway health check failed"
	@curl -f http://localhost:5921/api/health || echo "Backend health check failed"

# Help
help:
	@echo "Available commands:"
	@echo "  Development:"
	@echo "    dev-up       - Start development environment"
	@echo "    dev-down     - Stop development environment"
	@echo "    dev-logs     - View development logs"
	@echo "    dev-shell    - Open shell in backend container"
	@echo ""
	@echo "  Production:"
	@echo "    prod-up      - Start production environment"
	@echo "    prod-down    - Stop production environment"
	@echo "    prod-logs    - View production logs"
	@echo ""
	@echo "  Database:"
	@echo "    db-reset         - Reset MongoDB database"
	@echo "    db-backup        - Backup MongoDB database"
	@echo "    db-restore       - Restore database (use: make db-restore FILE=backup/file.archive)"
	@echo "    db-list-volumes  - List MongoDB volumes"
	@echo "    mongo-shell      - Open MongoDB shell"
	@echo ""
	@echo "  Utilities:"
	@echo "    health       - Check service health"
	@echo "    clean        - Remove containers and networks"
	@echo "    clean-all    - Remove everything including volumes"

.PHONY: up down build logs restart shell ps dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps backend-shell gateway-shell mongo-shell prod-up prod-down prod-build prod-logs prod-restart backend-build backend-install backend-type-check backend-dev db-reset db-backup clean clean-all clean-volumes status health help

# Allow passing arguments to make targets
%:
	@: