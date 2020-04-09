FROM centos:8 

ENV USER_ID=900 \
	GROUP_ID=900 \
	POWERDNS_VERSION=4.3 \
	SUMMARY="Platform for running PowerDNS $POWERDNS_VERSION" \
	DESCRIPTION="PowerDNS is a DNS server, written in C++ and licensed under the GPL. \
PowerDNS features a large number of different backends ranging from simple BIND style \
zonefiles to relational databases and load balancing/failover algorithms." \
    MYSQL_AUTOCONF=true \ 
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306" \
    MYSQL_USER="root" \
    MYSQL_PASS="root" \
    MYSQL_DB="pdns"


LABEL maintainer="admin@idwrx.com" \
	summary="${SUMMARY}" \
	description="${DESCRIPTION}" \
	name="idwrx/powerdns"

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r -g $GROUP_ID pdns && useradd -r -g pdns -u $USER_ID pdns 

RUN	dnf -y clean all && \
    dnf -y --nodoc --setopt=install_weak_deps=false update && \
    dnf -y erase acl bind-export-libs cpio dhcp-client dhcp-common dhcp-libs \
        ethtool findutils hostname ipcalc iproute iputils kexec-tools \
        less lzo pkgconf pkgconf-m4 procps-ng shadow-utils snappy squashfs-tools \
        vim-minimal xz && \
	dnf -y autoremove && \
	dnf -y install epel-release && \
	dnf -y install 'dnf-command(config-manager)' && \
	dnf config-manager --set-enabled PowerTools && \
	curl -o /etc/yum.repos.d/powerdns-auth-43.repo https://repo.powerdns.com/repo-files/centos-auth-43.repo && \
	dnf -y install --nodoc mysql pdns pdns-backend-mysql && \
	dnf -y clean all 

RUN cp /etc/pdns/pdns.conf /etc/pdns/pdns.conf.example
COPY ./pdns.conf ./schema.sql /etc/pdns/
COPY ./entrypoint.sh /
RUN mkdir /etc/pdns/conf.d /var/run/pdns
RUN chmod 755 /entrypoint.sh
RUN chown pdns:pdns /var/run/pdns 


EXPOSE 5353/tcp 5353/udp

USER pdns

ENTRYPOINT ["/entrypoint.sh"]

