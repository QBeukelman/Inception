# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: qbeukelm <qbeukelm@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/06 13:14:46 by qbeukelm          #+#    #+#              #
#    Updated: 2025/08/06 13:18:57 by qbeukelm         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #


# Latest stable version Debian 12
FROM debian:bookworm-slim

# Install packages
RUN apt-get update && \
	apt-get install -y mariadb-server && \
	rm -rf /var/lib/apt/lists/*

# Expose MySQL port
EXPOSE 3306

# Define entrypoint / command
CMD ["mysqld"]
