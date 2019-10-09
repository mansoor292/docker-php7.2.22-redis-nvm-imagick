FROM php:7.2.22-apache

#Install Git
RUN apt-get update \
    && apt-get install -y git \
    && apt-get install -y nano \ 
    && apt-get install -y unzip

# Make ssh dir
RUN mkdir /root/.ssh/
# Create id_rsa from string arg, and set permissions
RUN touch /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa \
# Create known_hosts
&& touch /root/.ssh/known_hosts \
# Add git providers to known_hosts
&& ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts 

RUN apt-get install -y libpq-dev
RUN docker-php-ext-install pdo pdo_pgsql pgsql
RUN a2enmod rewrite && a2enmod proxy && a2enmod proxy_http && a2enmod proxy_balancer && a2enmod lbmethod_byrequests 

#add image libraries
RUN apt-get install -y \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libpng-dev libxpm-dev \
    libfreetype6-dev

RUN docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/include/\
    --with-png-dir=/usr/include/\
    --with-freetype-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

RUN cd ~
#install imagick
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
	&& docker-php-ext-enable imagick


#install s3fs
RUN apt-get update && apt-get install -y wget automake autotools-dev g++ git libcurl4-gnutls-dev libfuse-dev libssl-dev libxml2-dev make pkg-config \
    && git clone https://github.com/s3fs-fuse/s3fs-fuse &&\
    wget https://github.com/Yelp/dumb-init/releases/download/v1.0.1/dumb-init_1.0.1_amd64.deb && dpkg -i dumb-init_*.deb && rm dumb-init_*.deb

WORKDIR s3fs-fuse
RUN ./autogen.sh && ./configure --prefix=/usr --with-openssl && make && make install

#install XDebug
RUN yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini
    

WORKDIR /var/www/html
#Install Node-6
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
ENV NODE_VERSION=7.10.1
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}\
 && . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}\
 && . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}\
 && node --version && npm --version

RUN npm i pm2 -g

#install legacy php libraries
#Get Slim from the URL unzip and move it to the library
COPY src/Slim.zip /tmp
RUN unzip /tmp/Slim.zip -d /usr/local/lib/php
	
#Get Smarty from the URL unzip and move it to the library
COPY src/Smarty.zip /tmp
RUN unzip /tmp/Smarty.zip -d /usr/local/lib/php

#Get lessphp from the src unzip and move it to the library
COPY src/lessphp.zip /tmp
RUN unzip /tmp/lessphp.zip -d /usr/local/lib/php



EXPOSE 80

    
