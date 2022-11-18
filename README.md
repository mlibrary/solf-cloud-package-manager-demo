
# Demo of SolrCloud package manager

This demo shows how to use the Solr package manager for loading custom plugins in a SolrCloud collection, where the plugin is explicitly referenced in the configuration `.xml` files.

## Prerequisites
You need the following installed on your workstation:
* Docker
* Docker compose
* bash
* openssl
* curl

## Set-up
1. Clone this repository
2. Run the script `set_up_rsa_keys.sh` This will generate two files: `demo.pem` and `demo_public.der`. These are the keys needed to upload packages directly to SolrCloud.
```
./set_up_rsa_keys.sh   
```
3. Start docker-compose
```
docker-compose up   
```
4. Open your browser to http://localhost:8983 and if all goes well you SolrCloud should have started
## Exploring the set-up

First, open up `set_up_sa_keys.sh`. What it's doing is generating a couple of keys for securing packages sent to SolrCloud. The first command generates the private key. The second generates the public key. The public key will get stored in Zookeeper. The private key will be used to generate a signature for the plugin files to be uploaded with the package manager. When Zookeeper gets the plugin, it will check the signature against all of the public keys it has stored. If there's a match it will allow the plugin to be loaded. If not the plugin won't be uploaded. 

Next open up `docker-compose.yml`. Not a lot going on in here. It has a `solr` service that's using the standard `solr:9.0` docker image. It opens up the default port for Solr so you can load up the admin interface in the browser. The next two sections are a little different.

In the `volumes` section it maps the public key to a location in the Solr container. This is so we can run in the container the `bin/solr package add-key` command with the public key. AFAICT there isn't a way to upload the key with the config API. 

In the command section we run `solr-fg -c -Denable.packages=true`. `solr-fg` is runs Solr in the foreground. `-c` starts Solr in SolrCloud mode. `-Denable.packages=true` starts Solr with the package manager enabled.

## Uploading a package directly to SolrCloud
In the `lib` folder is the file `runtimelibs.jar`. We want to get that `jar` file into SolrCloud with the package manager. The script `upload_plugins.sh` has instructions to do this. Open it up.

The first line is 
```
docker-compose exec solr bin/solr package add-key /demo_public.der 
```

This takes the public key file, `demo_public.der` that we put into the Solr container with the `volumes` element in the `solr` service in `docker-compose.yml`, and loads it into Zookeeper. 

Next we define the variables `jar`, `package_name`, `package_version`

Line 16 generates the signature for the `jar` file we want to upload and assigns it to the variable `signature` 
```
signature=$(openssl dgst -sha1 -sign demo.pem lib/$jar | openssl enc  -base64 | sed 's/+/%2B/g' | tr -d \\n  );
```

Line 19 uploads the jar to Zookeper using the cluster api. 
```
curl --data-binary @lib/$jar -X PUT  http://localhost:8983/api/cluster/files/$package_name/$package_version/$jar?sig=$signature 
```

Line 22 creates the package based on the uploaded file. 
```
curl http://localhost:8983/api/cluster/package -H 'Content-type:application/json' -d  "
  {'add': {
           'package' :'${package_name}',
           'version':'${package_version}',
           'files' :['/${package_name}/${package_version}/$jar']
         }
  }
"
```

To see what this did, go to `localhost:8983` , and go to Cloud --> Tree and then expand `/packagestore`. You'll see the jar in there. Expand `_trusted_` and you'll see the key `demo_public.der`

![SolrCloud admin panel with expanded directories related to the packagestore](imgs/screenshot1.png?raw=true "SolrCloud admin panel with expanded directories related to the packagestore")

So, the package was successfully uploaded to zookeeper. 

To see where the file is on the Solr container run the following in your terminal:
```
docker-compose exec solr ls  /var/solr/data/filestore/demo_pkg/1.0.0
```

You should see `runtimelibs.jar` listed. The package manager will make this jar available in this location on every Solr node.

## Using the package in a configset
The `demo` folder contains the `_default` configset with a single change. It's on Line 94 of `solrconfig.xml`
```
<requestHandler name="/test" class="demo_pkg:org.apache.solr.core.RuntimeLibReqHandler"></requestHandler>
```

`class="PACKAGE_NAME:full.path.to.MyClass"` is the way to reference a plugin from the package manager. 

The script `zipit.sh` creates a zipped version of the `demo` folder, uploads the zip as as a configset using the config API, and then creates a new SolrCloud collection based on that configset. It also deletes existing `demo` configsets and collections before uploading or creating new ones. 

Open up `zipit.sh` to see exactly what it's doing. Each line is commented, so I won't repeat it here. 

Run `./zipit.sh`. The response from the create collection command should look something like this: 
```
{
  "responseHeader":{
    "status":0,
    "QTime":1726},
  "success":{
    "172.30.0.2:8983_solr":{
      "responseHeader":{
        "status":0,
        "QTime":1198},
      "core":"demo_shard1_replica_n1"}}}
```


## When would you do this?
I imagine using this as a way to test out a new version of a plugin on one's workstation. You have the `.jar` file, but you don't want to load it into a package repository yet. Have a script like `set_up_rsa_keys.sh`, load the key into Solr somehow, then have a script like `upload_plugins.sh` . Then you can reference the package in the solr config `xml` with the package manager syntax. 

I don't think this method makes sense in a production context.

## Using a package repository

### What goes in a package repository
A package repository is a website that has three things in it:
* `publickey.der` 
* `repository.json`
* `jar` files

This demo repo is also a package repository! Well not the whole thing, but the `repo` folder is. It has a `publickey.der` that is actually committed to the repository and not auto generated with the `set_up_rsa_keys.sh` script. It has a `jar` file. In fact it's the same `jar` file that's in the  `lib` directory. And it has `repository.json` 

There's more that you can put in a `repository.json`, but this minimal version will work for manually configured plugins. (I.E. what we did with adding a line to `solrconfig.xml` that references the plugin.)

### Using a package repository

First let's restart docker compose to remove the configset that's there and remove the plugins that got added.

```
docker-compose down
docker-compose up
```

The script `upload_repo.sh` will load the package using the package repository.

Open up `upload_repo.sh` and read it. It has two lines and is commented.

run `./upload_repo.sh`

Then you can go to `localhost:89893` to see that it looks similar to when we uploaded the packages manually.

Then run `./zipit.sh` and it should load a new demo collection.

## Keeping the package repository well signed

This repository has a github action `.gihtub/workflows/sign_packages`  which on every push to the repository, uses the `PRIVATE_KEY` stored as a github repository secret to update `repository.json` with signatures for each file. The action runs the script `bin/sign_it.rb` If `repository.json` changes, the change is automatically committed. 

## Exercises for the reader

More things you can do to get a better understanding of the package manager
* Try running `.zipit.sh` when there aren't any plugins loaded. 
* Try messing up the signature and then trying to load the plugin
* Create your own package repository. See what happens if you use version number that doesn't have three parts. 
* Try creating a package with multiple jars 
* Try loading packages from `mlibrary/umich-solr-plugins`

## Sources / Further reading
* The [official Solr package manager documentation](https://solr.apache.org/guide/solr/latest/configuration-guide/package-manager.html). In particular, I found the [Full Working Example](https://solr.apache.org/guide/solr/latest/configuration-guide/package-manager-internals.html#full-working-example) on the Package Manager Internals very useful.
* [Youtube Presentation](https://www.youtube.com/watch?v=K5kSgTvVFKc) by Solr developer David Smiley
* [Tutorial](https://sematext.com/blog/solr-plugins-system/) by Sematext
