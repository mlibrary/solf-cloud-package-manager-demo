#create a zip of the configset
cd demo
zip -r ../demo.zip .
cd ..

#delete an existing demo configset if it's there. This will give an error the first time it's run.
curl -X DELETE   "http://localhost:8983/api/cluster/configs/demo"

#use the cluster api to upload the configset
curl -X PUT   --header "Content-Type: application/octet-stream"   --data-binary @demo.zip   "http://localhost:8983/api/cluster/configs/demo"

#delete the demo collection if it already exists. 
curl 'http://localhost:8983/solr/admin/collections?action=DELETE&name=demo'

#create the demo collection based on the demo configset
curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=demo&numShards=1&collection.configName=demo'
