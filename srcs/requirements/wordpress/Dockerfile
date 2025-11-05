# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: qbeukelm <qbeukelm@student.42.fr>            +#+                      #
#                                                    +#+                       #
#    Created: 2025/08/06 13:14:55 by qbeukelm      #+#    #+#                  #
#    Updated: 2025/11/05 09:25:55 by quentinbeuk   ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

# Latest stable version Debian 12
FROM debian:bookworm-slim

# Avoid interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Install PHP-FPM (FastCGI Process Manager), MySQL driver, curl, certs and clear apt cache
RUN apt-get update && apt-get install -y --no-install-recommends \
      php-fpm php-cli php-mysql curl ca-certificates unzip \
  && rm -rf /var/lib/apt/lists/*

# Make PHP-FPM listen on TCP:9000
RUN sed -ri 's|^;?listen\s*=.*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf \
 && mkdir -p /run/php

# Install WP-CLI
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

# Copy and run init script
COPY ./tools/wp.sh /usr/local/bin/wp.sh
RUN chmod +x /usr/local/bin/wp.sh

WORKDIR /var/www/html
EXPOSE 9000

CMD ["/usr/local/bin/wp.sh"]
