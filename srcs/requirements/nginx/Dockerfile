# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: qbeukelm <qbeukelm@student.42.fr>            +#+                      #
#                                                    +#+                       #
#    Created: 2025/08/06 13:14:51 by qbeukelm      #+#    #+#                  #
#    Updated: 2025/11/05 18:54:38 by quentinbeuk   ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

# Latest stable version Debian 12
FROM debian:bookworm-slim

# Avoid interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Install nginx, openssl and ca certs
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create runtime directories for Nginx
# Needed dirs
RUN mkdir -p /run/nginx /etc/nginx/conf.d /etc/nginx/certs /etc/nginx/templates /var/www/html

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80 443

# Start from entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
