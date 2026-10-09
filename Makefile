COMPOSE_FILE := srcs/docker-compose.yml
ENV_FILE := srcs/.env
COMPOSE := docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

-include $(ENV_FILE)

LOGIN ?= $(USER)
DATA_DIR := /home/$(LOGIN)/data
SECRET_FILES := secrets/db_root_password.txt secrets/db_password.txt \
	secrets/wp_admin_password.txt secrets/wp_user_password.txt

.PHONY: all setup build up down start stop restart logs ps clean fclean re check help

all: setup build up

setup: $(SECRET_FILES)
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

secrets/%.txt:
	@mkdir -p secrets
	@umask 077; openssl rand -base64 32 | tr -d '\n' > $@
	@echo "Generated $@"

build: setup
	$(COMPOSE) build

up: setup
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

check:
	$(COMPOSE) config --quiet
	@echo "Compose configuration is valid."

clean:
	$(COMPOSE) down --rmi local --remove-orphans

fclean: clean
	@echo "Persistent data is stored in $(DATA_DIR)."
	@echo "To delete it, run: sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress"

re: fclean all

help:
	@echo "make          Generate secrets, build images, and start the stack"
	@echo "make down     Stop and remove containers and the network"
	@echo "make logs     Follow service logs"
	@echo "make ps       Show container health and status"
	@echo "make clean    Remove containers and locally built images"

