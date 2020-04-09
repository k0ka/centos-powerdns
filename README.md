# PowerDNS Docker Container

* CentOS8 based Image
* MySQL backend 
* DNSSEC support optional
* Automatic MySQL database initialization
* PowerDNS version 4.3
* Graceful shutdown using pdns_control
* Rootless - listens to port 5353

## Usage

```shell
# Start a MySQL Container
$ docker run -d \
  --name pdns-mysql \
  -e MYSQL_ROOT_PASSWORD=supersecret \
  -v $PWD/mysql-data:/var/lib/mysql \
  mariadb:10.1

$ docker run --name pdns \
  --link pdns-mysql:mysql \
  -p 53:5353 \
  -p 53:5353/udp \
  -e MYSQL_USER=root \
  -e MYSQL_PASS=supersecret \
  quay.io/idwrx/powerdns \
    --cache-ttl=120 \
    --allow-axfr-ips=127.0.0.1,123.1.2.3
```

## Configuration

**Environment Configuration:**

* MySQL connection settings
  * `MYSQL_HOST=mysql`
  * `MYSQL_USER=root`
  * `MYSQL_PASS=root`
  * `MYSQL_DB=pdns`
  * `MYSQL_DNSSEC=no`
* Want to disable mysql initialization? Use `MYSQL_AUTOCONF=false`
* DNSSEC is disabled by default, to enable use `MYSQL_DNSSEC=yes`
* Want to use own config files? Mount a Volume to `/etc/pdns/conf.d` or simply overwrite `/etc/pdns/pdns.conf`

**PowerDNS Configuration:**

Append the PowerDNS setting to the command as shown in the example above.  
See `docker run --rm psitrax/powerdns --help`


## License

[GNU General Public License v2.0](https://github.com/PowerDNS/pdns/blob/master/COPYING) applyies to PowerDNS and all files in this repository.


## Maintainer

* koka <admin@idwrx.com>

### Credits

* Christoph Wiechert <wio@psitrax.de>: Base image - https://github.com/psi-4ward/docker-powerdns
* Mathias Kaufmann <me@stei.gr>: Reduced image size

