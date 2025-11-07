# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: qbeukelm <qbeukelm@student.42.fr>            +#+                      #
#                                                    +#+                       #
#    Created: 2025/08/06 13:14:46 by qbeukelm      #+#    #+#                  #
#    Updated: 2025/11/07 13:11:13 by quentinbeuk   ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

# Latest stable version Debian 12
FROM debian:bookworm-slim

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-server mariadb-client ca-certificates gosu && \
    rm -rf /var/lib/apt/lists/*

# Allow external connections from other containers
RUN sed -ri 's/^(bind-address\s*=).*/\1 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    printf '\n[mysqld]\nskip-name-resolve\n' >> /etc/mysql/mariadb.conf.d/50-server.cnf

# Init/entry script
COPY tools/init-mariadb.sh /usr/local/bin/init-mariadb.sh
RUN chmod +x /usr/local/bin/init-mariadb.sh

# Expose MySQL port
EXPOSE 3306

# Define entrypoint / command
ENTRYPOINT ["/usr/local/bin/init-mariadb.sh"]
CMD ["mysqld"]
