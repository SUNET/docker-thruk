FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Depends for setting up a custom apt repo
RUN apt-get update && \
    apt-get install --no-install-recommends -y gpg curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Setup custom repo and install thruk
RUN echo 'deb http://download.opensuse.org/repositories/home:/naemon/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:naemon.list
RUN curl -fsSL https://download.opensuse.org/repositories/home:naemon/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_naemon.gpg > /dev/null


RUN apt-get update && \
    apt-get install --no-install-recommends -y thruk && \
    rm -rf /var/lib/apt/lists/*

COPY naemon.conf /etc/thruk/thruk_local.d/naemon.conf
COPY 99_thruk_local_d.conf /etc/thruk/thruk_local.d/99_thruk_local_d.conf

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
RUN echo "Listen 443" > /etc/apache2/ports.conf
COPY thruk.conf /etc/apache2/sites-available/thruk.conf
RUN a2ensite thruk

RUN a2enmod ssl rewrite headers proxy_http


COPY start.sh /start.sh

ENTRYPOINT ["/start.sh"]

