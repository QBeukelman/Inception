# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: qbeukelm <qbeukelm@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/06 12:35:35 by qbeukelm          #+#    #+#              #
#    Updated: 2025/08/06 13:01:47 by qbeukelm         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #


# Variables
COMPOSE = docker-compose
YML = docker-compose.yml

# Start and build project
# Builds Docker images, creates and startes containers (-d detached/in background)
up:
	$(COMPOSE) -f $(YML) up -d --build

# Stop and remove project
down:
	$(COMPOSE) -f $(YML) down

re:
	$(MAKE) down
	$(MAKE) up

clean:
	$(COMPOSE) -f $(YML) down -v --remove-orphans
	docker volume prune -f

fclean:
	docker rmi $$(docker images -q)

.PHONY: up down re clean flcean
