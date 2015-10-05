# Akeneo Web
FROM debian:jessie
MAINTAINER s7b4 <baron.stephane@gmail.com>

# Base + Akeneo requirements
RUN apt-get update \
	&& apt-get install --no-install-recommends --yes \
		ca-certificates \
		openssh-client \
		curl \
		nano \
		git \
		apache2 \
		php5 \
		php5-cli \
		php5-curl \
		php5-gd \
		php5-intl \
		php5-mysqlnd \
		php5-mcrypt \
		php5-apcu \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Apache
COPY config/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin

# PHP
COPY config/apache-php.ini /etc/php5/apache2/php.ini
COPY config/cli-php.ini /etc/php5/cli/php.ini

# Clean
RUN rm -rf /tmp/* /var/tmp/*

VOLUME /var/www/html
EXPOSE 80

COPY scripts/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["apache2", "-D", "FOREGROUND"]