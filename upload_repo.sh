docker-compose exec solr bin/solr package add-repo solr-package-manager-demo https://raw.githubusercontent.com/mlibrary/solr-cloud-package-manager-demo/main/repo
docker-compose exec solr bin/solr package install demo_pkg 
