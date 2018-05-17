#!/bin/bash

pathToData="../data/"
pathToLog="$pathToData"log/
# rm -rf "$pathToData"
mkdir "$pathToData"
mkdir "$pathToLog"

sed -i "s#<tr><td><div class='utilities-area'><div class='logo-section'><div class='show-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo.jpg'></a></div><div class='hide-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo_mobile.jpg'></a></div></div></div></td></tr>##g" "$pathToData"dl.acm.org/pubs/lib/js/divTab.js

while read i; do
  id=${i#*\?};
  echo "Processing $i:"

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

done < data.txt
#done < test.txt
