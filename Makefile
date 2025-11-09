# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Makefile                                           :+:    :+:             #
#                                                      +:+                     #
#    By: qbeukelm <qbeukelm@student.42.fr>            +#+                      #
#                                                    +#+                       #
#    Created: 2025/08/06 12:35:35 by qbeukelm      #+#    #+#                  #
#    Updated: 2025/11/09 22:25:56 by quentinbeuk   ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

# Prefer docker v2
COMPOSE ?= $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)
YML ?= srcs/docker-compose.yml

# Start and build project
# Builds Docker images, creates and startes containers
#	-d : Detached mode, or in background (Avoid excessive logging).
up:
	$(COMPOSE) -f $(YML) up -d --build

# Stop and remove project
down:
	$(COMPOSE) -f $(YML) down

re:
	$(MAKE) down
	$(MAKE) up

logs:
	$(COMPOSE) -f $(YML) logs -f --tail=200

clean:
	$(COMPOSE) -f $(YML) down -v --remove-orphans
	docker volume prune -f

fclean:
	docker rmi $$(docker images -q)

.PHONY: up down re clean fclean
