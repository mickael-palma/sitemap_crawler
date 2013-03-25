sitemap_crawler estt un outil qui permet de tester des sites avec l'application [spypp_server](https://github.com/powermike/spypp_server)

# Installation

Télécharger les fichiers [sitemap_crawler](https://github.com/powermike/sitemap_crawler/archive/master.zip).

Aller dans le répertoire et rendre le fichier exécutable et installer les gems nécessaires :
```shell
$ cd sitemap_crawler
sitemap_crawler$ chmod 755 sitemap_crawler.rb
sitemap_crawler$ bundle
```

Les gems utilisées sont :
* [em-synchrony](https://github.com/igrigorik/em-synchrony)
* [em-http-request](https://github.com/igrigorik/em-http-request)
* [nokogiri](https://github.com/sparklemotion/nokogiri)
* [anemone](https://github.com/chriskite/anemone)
* [builder](https://github.com/jimweirich/builder)
* [sqlite3-ruby](https://github.com/luislavena/sqlite3-ruby)

Pour lancer la commande :
```shell
sitemap_crawler$ ./sitemap_crawler.rb
```

Vous obtenez l'aide du fichier :
```shell
sitemap_crawler$ ./sitemap_crawler.rb
Usage: ./sitemap_crawler.rb COMMAND [OPTIONS]

Commands
     urls: get all urls from sitemap
     crawl_all: crawl every sitemap url
     crawl_it: crawl one url
     search: query website search engine
     sitemap: generate a sitemap. -u and -w are required

Options
    -T, --threads=THREADS            how many threads you want to use for sitemap command. Default is : 4
    -r, --robot                      don't obey the robots exclusion protocol. Default is : true
    -q, --query                      for sitemap command skip any link with a query string? e.g. http://foo.com/?u=user. Default is : true
    -s, --skip=SKIP                  filter for sitemap command. Use Regex to define URLs which should not be followed
    -f, --filter=FILTER              filter for sitemap URLs using Regular Expressions
    -l, --layout=LAYOUT              you can change the product display layout. 'normal' and 'light' are available. Default is : normal
    -t, --term=TERM                  term you want to search for with the search command
    -w, --website=NAME               website name you want to focus on
    -u, --url=URL                    URL you want to crawl with crawl_it or sitemap command. Ex: http://www.test.com
    -c, --concurrency=CONCURRENCY    how many request per second. Default is : 25
    -p, --port=PORT                  spypp_server port. Default is : 5001
    -h, --host=HOSTNAME              hostname of the spypp_server. Default is : http://0.0.0.0
        --help                       show this help, then exit
```

# Les commandes disponibles
Avant d'utiliser sitemap_crawler assurez-vous que [spypp_server](https://github.com/powermike/spypp_server) est bien lancé sur le **port 5001**.
De même assurez-vous que le site testé est bien géré par spypp_server.

Pour chaque commande vous devez au moins spécifier un nom de site avec l'option '-w'
```shell
./sitemap_crawler.rb COMMAND -w website_name
```

Si votre spypp_server est sur une autre machine vous pouvez le spécifier :
./sitemap_crawler.rb COMMAND -h http://sc-server.herokuapp.com -p 80 -w website_name

## urls
Cette commande permet d'avoir une liste des urls contenues dans un sitemap.
```shell
$./sitemap_crawler.rb urls -w opticienonline
```
affiche :
```shell
"http://www.opticienonline.com/lunettes.html"
...
"http://www.opticienonline.com/national-geographic.html"
"--------------------------------------------"
" We found 1042 urls"
"--------------------------------------------"
  0.010000   0.000000   0.010000 (  0.190531)
```

Vous pouvez test des expressions régulières (/regexp/) pour filtre le sitemap :
```shell
$./sitemap_crawler.rb urls -w opticienonline -f /test/
```
qui donne :
```shell
"http://www.opticienonline.com/cebe-contest-visor-matt-white.html"
"http://www.opticienonline.com/cebe-contest-visor-matt-denim.html"
"http://www.opticienonline.com/cebe-contest-shiny-mettalic-black.html"
"http://www.opticienonline.com/cebe-contest-shiny-mettalic-purple.html"
"http://www.opticienonline.com/cebe-contest-visor-matt-black.html"
"http://www.opticienonline.com/test"
"--------------------------------------------"
" We found 6 urls"
"--------------------------------------------"
  0.000000   0.000000   0.000000 (  0.147964)
```

## crawl_all
Cette commande permet de crawl toutes les pages du sitemap afin de déceler des erreurs dans la détection des pages produits de spypp_server.

```shell
$./sitemap_crawler.rb crawl_all -w opticienonline
```

Plusieurs options sont disponibles pour **crawl_all** :
* -f, --filter=FILTER
* -l, --layout=LAYOUT
* -c, --concurrency=CONCURRENCY

Avec l'option "-f /test/" vous aller crawler toutes les urls contenant le mot "test":
```shell
$./sitemap_crawler.rb urls -w opticienonline -f /test/
```

Avec l'option "-l light" vous allez avoir un affichage des informations produits essentiels :
```shell
"-------------------------------------------"
"http://www.opticienonline.com/tasco-world-class-20-60x80mm.html"
"-------------------------------------------"
""
"title : Tasco World Class 20-60x80mm"
"brand : Tasco"
"category : Longues vues"
"link : http://www.opticienonline.com/tasco-world-class-20-60x80mm.html"
"medias : http://www.opticienonline.com/media/catalog/product/cache/1/thumbnail/58x58/5e06319eda06f020e43594a9c230972d/w/c/wc20606045.jpg"
"price : 279.0"
""
"-------------------------------------------"
```

Par défaut, c'est l'affichage normal qui est utilisé :
```shell
"-------------------------------------------"
"http://www.opticienonline.com/pochette-optinett.html"
"-------------------------------------------"
""
"title : Optinett Pochette"
"brand : Optinett"
"category : Accessoires"
"link : http://www.opticienonline.com/pochette-optinett.html"
"medias : http://www.opticienonline.com/media/catalog/product/cache/1/thumbnail/58x58/5e06319eda06f020e43594a9c230972d/o/p/optinett-pochettel.jpg"
"price : 4.9"
"sale_price : 0"
"shipping_price : 5.5"
"availability : in stock"
"description : Les avantages des pochettes Optinett :- nettoyant- dégraissant- traitement antistatique Pratique :Le petit étui à emporter et à placer dans sa voiture, sa salle de bain, son sac à main pour essuyer ses lunettes où et quand on veut !"
"ean : "
"condition : new"
"mpn : pochette-optinett"
"isbn : "
"color : "
"size : "
"online_only : "
"review_score : "
""
"-------------------------------------------"
```

Avec l'option "-c 25", vous spécifiez le nombre de requêtes par seconde que le crawl va effectuer. Plus le chiffre est élevé, plus le crawl est rapide mais agressif pour le serveur distant. Le but est de trouver le meilleur compromis entre vitesse et efficacité. Par défaut, il est à "25" mais il arrive que certains serveurs n'encaisse pas plus que 10 req/s.
> S'il y a trop de pages marquées "... is not a product url" c'est que la valeur est trop élevée.

## crawl_it
Permet de crawler une page spécifiée avec l'option "-u" :
```shell
$ ./sitemap_crawler.rb crawl_it -w opticienonline -u http://www.opticienonline.com/pochette-optinett.html
```

qui renvoie les informations produits trouvées sur la page :
```shell
"http://www.opticienonline.com/pochette-optinett.html"
"-------------------------------------------"
""
"title : Optinett Pochette"
"brand : Optinett"
"category : Accessoires"
"link : http://www.opticienonline.com/pochette-optinett.html"
"medias : http://www.opticienonline.com/media/catalog/product/cache/1/thumbnail/58x58/5e06319eda06f020e43594a9c230972d/o/p/optinett-pochettel.jpg"
"price : 4.9"
"sale_price : 0"
"shipping_price : 5.5"
"availability : in stock"
"description : Les avantages des pochettes Optinett :- nettoyant- dégraissant- traitement antistatique Pratique :Le petit étui à emporter et à placer dans sa voiture, sa salle de bain, son sac à main pour essuyer ses lunettes où et quand on veut !"
"ean : "
"condition : new"
"mpn : pochette-optinett"
"isbn : "
"color : "
"size : "
"online_only : "
"review_score : "
""
"-------------------------------------------"
  0.010000   0.000000   0.010000 (  0.785664)
```

Vous pouvez aussi changer d'affichage avec l'option "-l light" :
```shell
$ ./sitemap_crawler.rb crawl_it -w opticienonline -u http://www.opticienonline.com/pochette-optinett.html -l light
"http://www.opticienonline.com/pochette-optinett.html"
"-------------------------------------------"
""
"title : Optinett Pochette"
"brand : Optinett"
"category : Accessoires"
"link : http://www.opticienonline.com/pochette-optinett.html"
"medias : http://www.opticienonline.com/media/catalog/product/cache/1/thumbnail/58x58/5e06319eda06f020e43594a9c230972d/o/p/optinett-pochettel.jpg"
"price : 4.9"
""
"-------------------------------------------"
  0.000000   0.000000   0.000000 (  0.742250)
```

## search
C'est l'équivalent de crawl_it mais pour la page de recherche. La liste des produits trouvés sur la page de recherche du site vous est ainsi retournée avec les informations de chaque produit.

Vous spécifiez le mot que vous chercher ici "mambo":
```shell
$ ./sitemap_crawler.rb search -w opticienonline -t mamba
```

Vous pouvez utiliser également l'option "-l light" pour reduire n'afficher que l'essentiel des informations.
```shell
$ ./sitemap_crawler.rb search -w opticienonline -t mamba -l light
```

qui affiche :
```shell
"-------------------------------------------"
""
"title : Bollé Safety Mamba"
"brand : Bollé"
"category : "
"link : http://www.opticienonline.com/bolle-safety-mamba-2.html"
"medias : http://www.opticienonline.com/media/catalog/product/cache/1/small_image/150x150/5e06319eda06f020e43594a9c230972d/m/a/mampsj.jpg"
"price : 19.9"
""
"-------------------------------------------"
...
"-------------------------------------------"
""
"title : Bollé Safety Mamba"
"brand : Bollé"
"category : "
"link : http://www.opticienonline.com/bolle-safety-mamba.html"
"medias : http://www.opticienonline.com/media/catalog/product/cache/1/small_image/150x150/5e06319eda06f020e43594a9c230972d/m/a/mampsi.jpg"
"price : 19.9"
""
"-------------------------------------------"
"--------------------------------------------"
" We found 3 products"
"--------------------------------------------"
  0.000000   0.000000   0.000000 (  0.662275)
```

## sitemap
Cette commande permet de générer un fichier sitemap.xml utilisable par spypp_server.
Par défaut le crawler :
* utilise 4 démons
* respecte les règles contenus dans le fichier robots.txt
* ne crawl pas les urls contenant des variables (ex: http://foo.com/?u=user)

Plusieurs options sont disponibles pour **sitemap** :
* -q, --query
* -T, --threads=THREADS
* -r, --robot
* -s, --skip=SKIP

Voici la commande par défaut :
```shell
$ ./sitemap_crawler.rb sitemap -u http://www.opticienonline.com -w opticienonline
```

Elle générer 2 fichiers dans le répertoire "sitemaps" :
* opticienonline.db fichier nécessaire au crawler
* opticienonline.xml le sitemap généré au format XML

Si vous voulez accélérer le crawl vous pouvez augmenter le nombre de démons avec l'option "-T" :
```shell
$ ./sitemap_crawler.rb sitemap -u http://www.opticienonline.com -w opticienonline -T 10
```

Si le robots.txt est trop restrictif, vous pouvez vous en passer avec l'option "-r". Le crawler ne tiendra pas compte du robotx.txt :
```shell
$ ./sitemap_crawler.rb sitemap -u http://www.opticienonline.com -w opticienonline -r
```

Si les pages produits ont des urls avec variables (ex: http://foo.com/page_produit?id=id_produit), vous devez activer le crawl de ce type d'urls avec l'option "-q"
```shell
$ ./sitemap_crawler.rb sitemap -u http://www.opticienonline.com -w opticienonline -q
```

Si vous avez identifier des pages inutiles sur le site que vous ne voulez pas avoir dans le sitemap, utilisez l'option "-s /regexp/".
Grâce à cette option le sitemap peut être énormément allégé.

Par exemple :
```shell
$ ./sitemap_crawler.rb sitemap -u http://www.opticienonline.com -w opticienonline -s /avis_conso/
```

Le sitemap ne contiendra aucune page d'avis consommateur.
