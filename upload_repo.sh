#!/usr/bin/bash

#adds the repository which lives at this github repository in the repo directory
docker-compose exec solr bin/solr package add-repo solr-package-manager-demo https://raw.githubusercontent.com/mlibrary/solr-cloud-package-manager-demo/main/repo

#this installs the demo_package which is part of the package repo
docker-compose exec solr bin/solr package install demo_pkg 
