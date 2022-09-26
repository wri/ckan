FROM phusion/baseimage:0.9.22
MAINTAINER Open Knowledge

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

ENV HOME /root
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_DATA /var/lib/ckan

# Install required packages
RUN apt-get -q -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
        python-minimal \
        python-dev \
        python-virtualenv \
        libevent-dev \
        libpq-dev \
        nginx-light \
        apache2 \
        libapache2-mod-wsgi \
        postfix \
        build-essential

# Install CKAN
RUN mkdir -p $CKAN_HOME $CKAN_CONFIG $CKAN_DATA
RUN chown www-data:www-data $CKAN_DATA

RUN virtualenv $CKAN_VENV/
RUN $CKAN_VENV/bin/pip install -U -i https://pypi.python.org/simple/ pip

COPY . $CKAN_HOME/src/ckan/
RUN $CKAN_VENV/bin/pip install -r $CKAN_HOME/src/ckan/requirements.txt
RUN $CKAN_VENV/bin/pip install -e $CKAN_HOME/src/ckan/
RUN ln -s $CKAN_HOME/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini

# Configure apache
COPY ./contrib/docker/apache.wsgi $CKAN_CONFIG/apache.wsgi
COPY ./contrib/docker/apache.conf /etc/apache2/sites-available/ckan_default.conf
RUN echo "Listen 8080" > /etc/apache2/ports.conf
RUN a2ensite ckan_default
RUN a2dissite 000-default


# Configure nginx
COPY ./contrib/docker/nginx.conf /etc/nginx/nginx.conf
RUN mkdir /var/cache/nginx

# Configure postfix
COPY ./contrib/docker/main.cf /etc/postfix/main.cf

# Configure runit
COPY ./contrib/docker/my_init.d /etc/my_init.d
COPY ./contrib/docker/svc /etc/service
CMD ["/sbin/my_init"]

VOLUME ["/var/lib/ckan"]
EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*