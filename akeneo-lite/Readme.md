# akeneo-lite

## Prérequis

* [Docker compose](https://docs.docker.com/compose/)
* Un [token Github](https://github.com/settings/tokens) pour composer (droit repo uniquement)

## Variables d'environnement

* MYSQL_LINK: host pour mysql (default: mysql)
* MYSQL_DATABASE: base de données pour akeneo
* MYSQL_USER: utilisateur mysql pour akeneo
* MYSQL_PASSWORD: mot de passe pour $MYSQL_USER
* GITHUB_TOKEN: Token github pour installation via composer

## Compose

### `docker-compose.yml`

	web:
	  image: s7b4/akeneo-lite
	  links:
	    - mysql:mysql
	  ports:
	    - "8081:80"
	  env_file: .env
	mysql:
	  image: mysql:5.6
	  env_file: .env

Exemple de fichier [.env](https://raw.githubusercontent.com/s7b4/docker-akeneo/master/akeneo-lite/.env.dist) 

## Interface

* Login initial: admin / admin