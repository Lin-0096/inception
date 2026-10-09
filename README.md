*This project has been created as part of the 42 curriculum by lin.*

# Inception

## Description

Inception builds a small, reproducible web infrastructure with Docker Compose. Three
images are built from handwritten Dockerfiles based on Debian 12 (the penultimate
stable Debian release at the time this project was prepared):

- **NGINX** is the only public entry point. It exposes HTTPS on port 443 and accepts
  TLS 1.2 or TLS 1.3 only.
- **WordPress** runs with PHP-FPM on the private Docker network. It does not contain
  NGINX.
- **MariaDB** stores WordPress data and is reachable only on the private network.

The source tree contains the Compose file, one Dockerfile and configuration directory
per service, and small entrypoint scripts that perform first-run initialization before
starting the real foreground daemon as PID 1.

Persistent data is stored in two named Docker volumes backed by host directories under
`/home/<login>/data`. Passwords are generated into ignored files in `secrets/` and
mounted read-only under `/run/secrets`.

### Design choices

| Topic | Choice and reason |
| --- | --- |
| Virtual machines vs Docker | A VM virtualizes a complete operating system and kernel; containers share the host kernel and isolate processes. Docker is faster and lighter for these single-purpose services, while the required outer VM supplies the kernel boundary. |
| Secrets vs environment variables | Non-sensitive configuration is kept in `.env`. Passwords use Docker secrets, so they are mounted as files and do not appear in image layers or the Compose environment. |
| Docker network vs host network | A dedicated bridge network provides DNS-based service discovery and isolation. Host networking would remove that boundary and is prohibited by the subject. |
| Docker volumes vs bind mounts | Compose named volumes express lifecycle and ownership at the infrastructure level. The local driver binds them to the required `/home/<login>/data` paths so data remains easy to locate on the host. |

## Instructions

Prerequisites: a Linux virtual machine, Docker Engine with the Compose plugin, GNU
Make, OpenSSL, root/sudo access for `/home/<login>/data`, and a hosts entry for the
chosen domain.

1. Edit `srcs/.env`: replace `lin` with your 42 login, update the domain and email
   addresses, and keep the administrator username free of `admin`/`administrator`.
2. Map the domain locally, for example: `127.0.0.1 lin.42.fr` in `/etc/hosts` when the
   browser runs in the VM, or map it to the VM IP on the host machine.
3. Run `make`. This creates local secrets, data directories, builds all images, and
   starts the stack.
4. Open `https://lin.42.fr`. Accept the warning for the locally generated self-signed
   certificate.

Useful commands:

```sh
make ps       # service and health status
make logs     # follow logs
make down     # stop and remove containers/network; keep data
make clean    # also remove project images; keep persistent data
```

See `USER_DOC.md` for operations and `DEV_DOC.md` for implementation details.

## Resources

- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker secrets in Compose](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX TLS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WordPress WP-CLI documentation](https://make.wordpress.org/cli/handbook/)
- [MariaDB server documentation](https://mariadb.com/docs/server/)

AI was used to help translate the subject into a directory structure, draft service
configuration and initialization scripts, check requirement coverage, and prepare the
documentation. Every generated file should be reviewed, tested in the target VM, and
understood before evaluation; the project owner remains responsible for it.

