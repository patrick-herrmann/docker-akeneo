#! /bin/bash

set -e

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
	: ${MONGO_LINK:=mongo}
	: ${MYSQL_LINK:=mysql}

	if [ -z "$MONGO_DATABASE" ]; then
		echo >&2 'error: missing MONGO_* environment variables'
		exit 1
	fi

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
	: ${AKENEO_URL:="http://download.akeneo.com/pim-community-standard-v1.6-latest.tar.gz"}
	curl -L -s "$AKENEO_URL" | tar xzf - --directory /var/www/html --strip-components 1
	
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
	composer install --optimize-autoloader --prefer-dist
	composer --prefer-dist require doctrine/mongodb-odm-bundle 3.2.0
	composer config --unset github-oauth.github.com

	echo 'Activation MongoDB ...'
	sed -ri "s/^(\s*)\/\/ (.*)DoctrineMongoDBBundle\(\),/\1\2DoctrineMongoDBBundle(),/" app/AppKernel.php
	sed -ri "s/^(\s*)# mongodb_(server|database)/\1mongodb_\2/" app/config/pim_parameters.yml
	set_config mongodb_server "mongodb://$MONGO_LINK:27017" pim_parameters.yml
	set_config mongodb_database "$MONGO_DATABASE" pim_parameters.yml
	set_config pim_catalog_product_storage_driver "doctrine/mongodb-odm" pim_parameters.yml

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

	# Attente MongoDB
	TERM=dumb php -- "$MONGO_LINK" <<'EOPHP'
<?php
$stderr = fopen('php://stderr', 'w');
$maxTries = 10;
$linkOk = false;
do {
	try {
        $m = new MongoClient("mongodb://{$argv[1]}:27017");
        $linkOk = true;
	} catch (Exception $e) {
		fwrite($stderr, "\nMongo Connection Error: (" . $e->getMessage() . ")\n");
        --$maxTries;
        if ($maxTries <= 0) {
			exit(1);
		}
		sleep(15);
	}
} while (!$linkOk);
EOPHP
	echo 'MongoDB OK ...'

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

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/apache2/apache2.pid

# Variables apache
. /etc/apache2/envvars
exec "$@"
