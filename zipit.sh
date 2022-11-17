cd demo
zip -r ../demo.zip .
cd ..
curl -X DELETE   "http://localhost:8983/api/cluster/configs/demo"
curl -X PUT   --header "Content-Type: application/octet-stream"   --data-binary @demo.zip   "http://localhost:8983/api/cluster/configs/demo"
curl 'http://localhost:8983/solr/admin/collections?action=DELETE&name=demo'
curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=biblio&numShards=1&collection.configName=demo'
