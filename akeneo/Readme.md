# akeneo

## Prérequis

* [Docker compose](https://docs.docker.com/compose/)
* Un [token Github](https://github.com/settings/tokens) pour composer (droit repo uniquement)

## Variables d'environnement

* MYSQL_LINK: host pour mysql (default: mysql)
* MYSQL_DATABASE: base de données pour akeneo
* MYSQL_USER: utilisateur mysql pour akeneo
* MYSQL_PASSWORD: mot de passe pour $MYSQL_USER
* MONGO_LINK: host pour mongo (default: mongo)
* MONGO_DATABASE: base mongodb
* GITHUB_TOKEN: Token github pour installation via composer

## Compose

### `docker-compose.yml`

	web:
	  image: s7b4/akeneo
	  links:
	    - mongo:mongo
	    - mysql:mysql
	  ports:
	    - "8080:80"
	  env_file: .env
	mongo:
	  image: mongo:3
	mysql:
	  image: mysql:5.6
	  env_file: .env

Exemple de fichier [.env](https://raw.githubusercontent.com/s7b4/docker-akeneo/master/akeneo/.env.dist) 

## Interface

* Login initial: admin / admin