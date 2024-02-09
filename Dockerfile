FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Depends for setting up a custom apt repo
RUN apt-get update && \
    apt-get install --no-install-recommends -y gpg curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Setup custom repo and install thruk
RUN curl -sS https://labs.consol.de/repo/stable/RPM-GPG-KEY | gpg --dearmor > /usr/share/keyrings/labs.consol.de-5E3C45D7B312C643.gpg
RUN echo 'deb [signed-by=/usr/share/keyrings/labs.consol.de-5E3C45D7B312C643.gpg] http://labs.consol.de/repo/stable/debian bookworm main' > /etc/apt/sources.list.d/consol.list
RUN apt-get update && \
    apt-get install --no-install-recommends -y thruk && \
    rm -rf /var/lib/apt/lists/*

COPY naemon.conf /etc/thruk/thruk_local.d/naemon.conf
COPY 99_thruk_local_d.conf /etc/thruk/thruk_local.d/99_thruk_local_d.conf
COPY log4perl.conf /etc/thruk/log4perl.conf

# Install Shibboleth
RUN apt-get update && \
    apt-get install --no-install-recommends -y libapache2-mod-shib && \
    rm -rf /var/lib/apt/lists/*
# Ensure to follow SWAMIDs rules regarding metadata
RUN sed -i 's/default_bits=3072/default_bits=4096/' /usr/sbin/shib-keygen
COPY md-signer2.crt /etc/shibboleth/md-signer2.crt
COPY shibboleth2.xml /etc/shibboleth/shibboleth2.xml

# Disable apache default site and port 80
RUN a2dissite 000-default
RUN a2disconf other-vhosts-access-log
RUN echo "Listen 443" > /etc/apache2/ports.conf

# Output to stderr/stdout for better handling in a container environment
RUN sed -i 's#ErrorLog ${APACHE_LOG_DIR}/error.log#ErrorLog /dev/stderr#g' /etc/apache2/apache2.conf
RUN echo 'TransferLog /dev/stdout'  >> /etc/apache2/apache2.conf

COPY thruk.conf /etc/apache2/sites-available/thruk.conf
RUN a2ensite thruk

RUN a2enmod ssl rewrite headers proxy_http

# Output to stdout for better handling in a container environment
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/shibd.log
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/shibd_warn.log
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/signature.log
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/transaction.log


COPY start.sh /start.sh

ENTRYPOINT ["/start.sh"]

