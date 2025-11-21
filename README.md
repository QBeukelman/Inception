# Inception

## TODO

3. The importance of the file structure.

6. Restart the virtual machine. Ensure that all of the Wordpress data is still there.
---
<br/>


![Architecture](images/Inception.png)

mkdir -p ~/data/mariadb ~/data/wordpress ~/data/certs

[Docker CLI Reference](https://docs.docker.com/reference/cli/docker/)

[Git Example](https://github.com/Xperaz/inception-42)

[Eval Sheet](https://github.com/Khoubaib-Boughalmi/42-evals/blob/master/ng_3_inception.pdf)

[VM Installation](https://github.com/Bakr-1/inceptionVm-guide?tab=readme-ov-file)

[Debian Releases](https://www.debian.org/releases)


> _"Is the docker daemon running?"_ -> For MacOS, run `docker context use desktop-linux`

---
<br/>


# Evaluation

When evaluation starts, run:

```bash
# Clear all docker services
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null

# Delete volumes
sudo rm -rf ~/data/mariadb/* ~/data/certs/* ~/data/wordpress/*
```

**Login**: [https://qbeukelm.42.fr/wp-login.php](qbeukelm.42.fr/wp-login.php)


## Project Overview

### What is Docker

Docker is a container engine that runs applications in containers on top of the host OS kernel.

- **Container**: an isolated runtime (filesystem, process, network, users) that packages an app with its dependencies. Isolation is provided by the Linux namespace and C-Groups (control groups); not virtualization. Containers can share data with **volumes** and talk to eachother on Docker managed **networks**. Show running containers with `docker ps`.

- **Image**: a immutable, layered filesystem snapshot and metadata (entrypoint, default command, environment, exposed ports). Containers are running instances of images.

- **Volume**: is storage that lives outside a container's writable layer so that data persists when containers are recreated or updated.

- **Network**: allows contaienrs to communicate. Containters attached to the same network can reach eachother by **IP** and **Name** (Dockers DNS). A **netowrk driver** defines how the network works. E.g **bridge** is a private subnet on the machine.

- **Secrets**: pass sensitive data into a container. Secrets are not baked into the image, and are mounted as **read-only**. Secrets are not visible in `docker inspect`, env vars, and are only accessible at runtime. Only containers that explicitly list the secret get access to it.


### How Docker works

Docker is based on the **Client Daemon Model**. The client runs docker commands, which talk to dockerd over a local API. Docker provides a level of virtualization.

- **Client**: is any program that calles the **Docker Engine API**. E.g. CLI (Command-Line Interface) `docker ...`.

- **Daemon / Dockerd**: is program that runs as a background process. It builds images and runs containers.

- **Docker Compose**: is a **client** that reads a YAML file and asks the daemon to build and start all services together.

> **_Is using daemons a good idea?_** For Docker avoid daemon processes. Run services in the **foregroud** so they become **PID 1**. (`nginx -g daemon off;`, `php-fpm -F`, `mysqld`). This keeps signals, logs, heath, and lifecycle correct.


### Docker with / without Compose

- **Without Compose**: run a single image/container manually (`docker run ...`), and must configure networks, env vars, and volumes by hand every time.

- **With Compose**: declare the entire stack once, including inter-service networking and persistence. Compose ensures consistent, repeatable bring-ups with one command (`docker compose up`).


### Benifit of Docker compared to VM

1. **Footprint**: containers share host kerel, and are lighter and faster to start (ms/s) vs. VMs (boot OS, minutes).

2. **Density**: run many containers on the same host efficiently.

3. **Immitability**: images are versioned and reproducible.

4. **Isolation**: process, filesystem, network isolation without full hardware virtualization.

5. **Virtualization**: a VM virtualizes both the operating system kernel and the application layer. A Docker container virtualizes only the application layer, and runs on top of the host OS.

Docker containers are often used for web apps, APIs, sidecars (NGINX, Redis). For app packaging, conainers are the best fit. If you need different kernels or stronger isolation, VMs are a better fit.


### The importance of the directory structure

One of the main benifits of Docker is the **isloation** it provides. Scoping each image's build its own folder prevents leaking unrelated files into the Docker **build context**.

- **Build Context**: is the set of files that you send to the Docker engine when running `docker build`. Every `COPY`/`ADD` in a Docker file can only read files from inside this build context.

---
<br/>


# Networking and DNS

Docker compose creates private network `web`. All services are attached to this network and can comunicate to eacher **without exposing ports to the host**.

```bash
# List networks
docker network ls

# Inspect network
docker network inspect web
```

### Domain Name System (DNS)

> For Inception, DNS tries to answering: _"When I type `qbeukelm.42.fr` in a browser, how does this end up at my Nginx container?"_

1. Host Level (outside Docker): Connects `qbeukelm.42.fr` to the machine's locat IP e.g. `127.0.0.1`.

2. Doker level: `nginx` -> `wordpress` -> `mariadb` via Docker's internal DNS (Network) system using service names.

**Sockets**: is an end point for communication. `service name` + `port` comprise a socket. In this case, `mariadb:443`, enables other contains such as WordPress to communicate with MariaDB.

---
<br/>


# NGINX with SSL/TLS

NGINX is a high-performance, **event-driven** web server.

It can **serve static files** (HTML, CSS, images) very fast, act as a **gateway** to forward requests to backend apps, and act as a **load balancer** to spread load accross multiple backends.

- **Transport Layer Security (TLS)**: is the standard protocol that secures network traffic, and turns `http://` into `https://`. TLS provides encryption and authentication. It does this via a **handshake** where the client and server validate a certificate, agree on ciphers and derive session keys, then send encripted application data.

- **Secure Socket Layer (SSL)**: is the predecessor to TLS.

- **Self-Signed Certificate**: skips Certificate Authority (CA), and browsers do not trust it. You generate a **key pair (cyphers)** and a **certificate**, and sign the certificate with the same key.

	- **Certificate**: is a public key + identify wrapper. It proves that "the private key belongs to the domain".

	- **Private Key**: is just a big randon number used to **decrypt** and **prove idendity** (by creating signitures).

---
<br/>


# Wordpress with PHP-FPM and its Volume

Wordpress is a polular CMS (content management system) written in PHP. It gives an admin dashboard to publish posts/pages, install themes and plugins, and stores content in a **MySQL/MariaDB** database.

- **PHP-FPM**: (FastCGI Process Manager) is a process manager that runs a pool of worker processes behind an interface. It keeps PHP "warm", meaning there are already PHP works running, instead of starting a new process each time.

---
<br/>


# MariaDB and its Volume

MariaDB is an open-source **relational database server**, used to store structured data in tables, and query it with SQL. In a Wordpress stack, PHP connects to MariaDB to read/write posts, users, options, etc.

---
<br/>


# Testing

You should NOT be able to access the website via `http://<login>.42.fr` (http - s).

```bash
# View logs for one service
docker logs <nginx>

# View running containers
docker ps

# Check redirect
curl -I http://qbeukelm.42.fr

# HTTPS responds (-k for self-signed)
curl -vIk https://qbeukelm.42.fr

# Check certificate
openssl s_client -connect qbeukelm.42.fr:443 -servername qbeukelm.42.fr </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates

# Connect to 80 -> Expext failure
# (netcat)
nc -vz qbeukelm.42.fr 80

# TSL try v1.2 & v1.3
curl -vI --tlsv1.3 https://qbeukelm.42.fr

# Force TLS v1.1
openssl s_client -connect qbeukelm.42.fr:443 -tls1_1

# Check volumes
docker volume ls
docker volume inspect <name>
```


### Open MariaDB

```bash
# Open folder with docker-compose file
cd srcs

# Open a shell in the DB container
docker compose exec mariadb sh

# Inside the container, log in as root
mysql -uroot -p

# Login as user
mysql -h mariadb -u qbeukelm -p

# Query data with SQL
SHOW DATABASES;
USE wordpress;
SHOW TABLES;

# Show table of users
SELECT * FROM wp_users;
```

### Debian

```bash
# Switch to root user
su -

# Install sudo
apt-get update && apt-get upgrade && apt-get install sudo -y

# Add user to sudo
adduser <username> sudo

# Reboot VM
sudo reboot

# Open browser in VM
startx
# Right click -> Open browser
```
