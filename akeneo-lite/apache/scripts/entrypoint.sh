#! /bin/bash

set -e

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/apache2/apache2.pid

# Check install
DO_INIT_AKENEO="no"
if [ ! -f /var/www/html/app/config/parameters.yml ]; then
	DO_INIT_AKENEO="yes"
elif [ "$(grep -c 'installed:' /var/www/html/app/config/parameters.yml)" = "0" ]; then
	DO_INIT_AKENEO="yes"
fi

# Installation akeneo
if [ "$DO_INIT_AKENEO" = "yes" ]; then

	# Liens conteneurs
	: ${MYSQL_LINK:=mysql}

	if [ -z "$MYSQL_DATABASE" -o -z "$MYSQL_USER" -o -z "$MYSQL_PASSWORD" ]; then
		echo >&2 'error: missing MYSQL_* environment variables'
		exit 1
	fi

	if [ -z "$GITHUB_TOKEN" ]; then
		echo >&2 'error: missing GITHUB_TOKEN environment variable'
		exit 1
	fi

	sed_escape() {
		echo "'$@'" | sed 's/[\/&]/\\&/g'
	}

	set_config() {
		key="$1"
		value="$2"
		regex="^(\s*)$key\s*:"
		sed -ri "s/($regex\s*).*/\1$(sed_escape "$value")/" "app/config/$3"
	}

	echo 'Download akeneo ...'
	: ${AKENEO_URL:="http://download.akeneo.com/pim-community-standard-v1.3-latest.tar.gz"}
	curl -s "$AKENEO_URL" | tar xzf - --directory /var/www/html --strip-components 1
	
	cd /var/www/html

	echo 'Config akeneo ...'
	set_config database_host "$MYSQL_LINK" parameters.yml
	set_config database_name "$MYSQL_DATABASE" parameters.yml
	set_config database_user "$MYSQL_USER" parameters.yml
	set_config database_password "$MYSQL_PASSWORD" parameters.yml
	set_config secret $(head -c1M /dev/urandom | sha1sum | cut -d' ' -f1) parameters.yml
	cat app/config/parameters.yml

	echo 'Composer ...'
	composer config github-oauth.github.com "$GITHUB_TOKEN"
	composer install
	composer config --unset github-oauth.github.com

	# Attente MySQL
	TERM=dumb php -- "$MYSQL_LINK" "$MYSQL_USER" "$MYSQL_PASSWORD" <<'EOPHP'
<?php
$stderr = fopen('php://stderr', 'w');
$maxTries = 10;
do {
	$mysql = new mysqli($argv[1], $argv[2], $argv[3]);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(15);
	}
} while ($mysql->connect_error);
EOPHP
	echo 'MySQL OK ...'

	echo 'Setup akeneo ...'
	# désactivation données de démo
	set_config installer_data "PimInstallerBundle:minimal" pim_parameters.yml
	php app/console cache:clear --env=prod
	php app/console pim:install --env=prod
	
	echo 'Setting permissions ...'
	chown -R www-data:www-data /var/www/html

	echo 'Clean ...'
	rm -rf ~/.composer/cache

	cd /
fi

exec "$@"
