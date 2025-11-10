# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: qbeukelm <qbeukelm@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/06 13:14:51 by qbeukelm          #+#    #+#              #
#    Updated: 2025/11/10 10:08:17 by qbeukelm         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Latest stable version Debian 12
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install nginx, tools
# Delete APT list caches to shrink image layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        ca-certificates \
        netcat-traditional \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Create runtime directories
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/gen_certs.sh /usr/local/bin/gen_certs.sh
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/gen_certs.sh /usr/local/bin/entrypoint.sh

ENV DOMAIN=qbeukelm.42.fr APP_HOST=wordpress APP_PORT=9000

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

