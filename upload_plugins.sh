docker-compose exec solr bin/solr package add-key /demo_public.der

declare -A jars_to_package=( 
["runtimelibs3.jar"]="demo_pkg" 
)

declare -A jars_to_version=( 
["runtimelibs3.jar"]="1.0.0" 
)

for jar in "${!jars_to_package[@]}"; 
do 
  signature=$(openssl dgst -sha1 -sign demo.pem lib/$jar | openssl enc  -base64 | sed 's/+/%2B/g' | tr -d \\n  );
  echo $signature
  curl --data-binary @lib/$jar -X PUT  http://localhost:8983/api/cluster/files/${jars_to_package[$jar]}/${jars_to_version[$jar]}/$jar?sig=$signature
done

for jar in "${!jars_to_package[@]}"; 
do 
  curl http://localhost:8983/api/cluster/package -H 'Content-type:application/json' -d  "
    {'add': {
             'package' :'${jars_to_package[$jar]}',
             'version':'${jars_to_version[$jar]}',
             'files' :['/${jars_to_package[$jar]}/${jars_to_version[$jar]}/$jar']
           }
    }"
done

