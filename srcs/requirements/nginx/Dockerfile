# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: qbeukelm <qbeukelm@student.42.fr>            +#+                      #
#                                                    +#+                       #
#    Created: 2025/08/06 13:14:51 by qbeukelm      #+#    #+#                  #
#    Updated: 2025/11/06 13:51:26 by quentinbeuk   ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

# Latest stable version Debian 12
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install nginx + tools we need
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        ca-certificates \
        netcat-traditional \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Create runtime directories
RUN mkdir -p /run/nginx /etc/nginx/conf.d /etc/nginx/certs /etc/nginx/templates /var/www/html

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

