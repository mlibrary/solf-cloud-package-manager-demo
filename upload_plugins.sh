#!/usr/bin/bash

# loads the public key into Zookeeper
docker-compose exec solr bin/solr package add-key /demo_public.der

# the file name
jar="runtimelibs.jar"

# what to call the package
package_name="direct_demo_pkg"

# the package version
package_version="1.0.0"

# generates the signature for the jar file using the private key
signature=$(openssl dgst -sha1 -sign demo.pem lib/$jar | openssl enc  -base64 | sed 's/+/%2B/g' | tr -d \\n  );

# uploads the file to zookeeper, but doesn't actually add the package itself
curl --data-binary @lib/$jar -X PUT  http://localhost:8983/api/cluster/files/$package_name/$package_version/$jar?sig=$signature

# adds the package itself
curl http://localhost:8983/api/cluster/package -H 'Content-type:application/json' -d  "
  {'add': {
           'package' :'${package_name}',
           'version':'${package_version}',
           'files' :['/${package_name}/${package_version}/$jar']
         }
  }
"

