#!/bin/bash

pathToData="../data/"
pathToLog="$pathToData"log/
# rm -rf "$pathToData"
mkdir "$pathToData"
mkdir "$pathToLog"

mkdir -p "$pathToData"dl.acm.org/pubs/lib/css
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/css/main.css" -P "$pathToData"dl.acm.org/pubs/lib/css/
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/css/bootstrap.min.css" -P "$pathToData"dl.acm.org/pubs/lib/css/
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/css/bootstrap-theme.min.css" -P "$pathToData"dl.acm.org/pubs/lib/css/

mkdir -p "$pathToData"dl.acm.org/pubs/lib/js
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/js/jquery.min.js" -P "$pathToData"dl.acm.org/pubs/lib/js/
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/js/bootstrap.min.js" -P "$pathToData"dl.acm.org/pubs/lib/js/
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/js/bibCit.js" -P "$pathToData"dl.acm.org/pubs/lib/js/
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://dl.acm.org/pubs/lib/js/divTab.js" -P "$pathToData"dl.acm.org/pubs/lib/js/
wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
  "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_CHTML" -P "$pathToData"dl.acm.org/pubs/lib/js/

sed -i "s#<tr><td><div class='utilities-area'><div class='logo-section'><div class='show-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo.jpg'></a></div><div class='hide-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo_mobile.jpg'></a></div></div></div></td></tr>##g" "$pathToData"dl.acm.org/pubs/lib/js/divTab.js

#TODO: use the proceedings HTML and xpath to generate scripts/data.txt (list of URLs to process)
#XXX: At the moment, `scripts/data.txt` was derived from https://www2018.thewebconf.org/proceedings/ using the following script:
#`var s = []; document.querySelectorAll('a[href^="https://dl.acm.org/authorize?N"]').forEach(function(i){ s.push(i.href); }); console.log(s.join("\n"));`

while read i; do
  id=${i#*\?};
  echo "Processing $i:"
  wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
    --header 'Referer: https://www2018.thewebconf.org/proceedings/' "$i" -P "$pathToData"

  url=$(grep -E 'href="http://delivery.acm.org/' "$pathToData"authorize\?"$id" | sed -re 's#[^\"]*href="([^"]*)".*#\1#')

  rm "$pathToData"authorize\?"$id"

  echo "Processing images. Log stored at $pathToLog""$id".log
  wget --header 'User-Agent: free and open access 👍' --header 'Accept: */*' \
    -o "$pathToLog""$id".log -p -k --page-requisites -H -r -l 1 -D deliveryimages.acm.org --no-parent -e robots=off "$url" -P "$pathToData"

  savedTo=$(head "$pathToLog""$id".log | grep -E 'Saving to: ‘' | sed -r 's#[^‘]*‘([^’]*)’.*#\1#')

  pathToFile=${savedTo%\?*}

  filename=$(echo "$savedTo" | sed -r 's#&#&amp;#g')

  filename=${filename##*/}

  mv "$savedTo" "$pathToFile"

  sed -i "s#$filename##g" "$pathToFile"
  sed -i 's#http://deliveryimages.acm.org/#../../../../deliveryimages.acm.org/#g' "$pathToFile"
  sed -i 's#https://dl.acm.org/pubs/lib/css/#../../../../dl.acm.org/pubs/lib/css/#g' "$pathToFile"
  sed -i 's#https://dl.acm.org/pubs/lib/js/#../../../../dl.acm.org/pubs/lib/js/#g' "$pathToFile"
  sed -i 's#https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/#../../../../dl.acm.org/pubs/lib/js/#g' "$pathToFile"

#  firefox "$pathToFile"

  sleep 5s
done < data.txt
#done < test.txt
