# docker-akeneo

## Prérequis

* [Docker compose](https://docs.docker.com/compose/)
* Un [token Github](https://github.com/settings/tokens) pour composer (droit repo uniquement)

## Images

* **akeneo**: installation de akeneo avec *MySQL* et *MongoDB*.
* **akeneo-lite**: installation de akeneo avec *MySQL* uniquement.

## Configuration

Copier le fichier `.env.dist` en `.env` et modifier les valeurs

## Démarrage

    $ docker-compose build
    $ docker-compose up
    
## Interface

* Login initial: admin / admin