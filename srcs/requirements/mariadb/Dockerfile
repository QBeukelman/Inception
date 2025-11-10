# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: qbeukelm <qbeukelm@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/06 13:14:46 by qbeukelm          #+#    #+#              #
#    Updated: 2025/11/10 10:08:10 by qbeukelm         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Latest stable version Debian 12
FROM debian:bookworm-slim

# Install packages
# Delete APT list caches to shrink image layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-server mariadb-client ca-certificates gosu && \
    rm -rf /var/lib/apt/lists/*

# Allow external connections from other containers
# Find regex line that starts with `bind-address`, replaces `127.0.0.1` with `0.0.0.0`
# MariaDB now listens to all interfaces, to let other containers connect.
RUN sed -ri 's/^(bind-address\s*=).*/\1 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    printf '\n[mysqld]\nskip-name-resolve\n' >> /etc/mysql/mariadb.conf.d/50-server.cnf

# Init/entry script
COPY tools/init-mariadb.sh /usr/local/bin/init-mariadb.sh
RUN chmod +x /usr/local/bin/init-mariadb.sh

# Expose MySQL port
# Meaning only containers on network can connect, not the host or internet
EXPOSE 3306

# Define entrypoint
ENTRYPOINT ["/usr/local/bin/init-mariadb.sh"]

# What to run on container startup.
# Run daemon, in foreground as PID 1.
CMD ["mysqld"]
