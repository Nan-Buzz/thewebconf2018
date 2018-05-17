#!/bin/bash

set -e

pathToData="../data/"
pathToDoi="../doi"
pathToLog="$pathToData"log/
# rm -rf "$pathToData"
mkdir -p "$pathToData" "$pathToLog"

sed -i "s#<tr><td><div class='utilities-area'><div class='logo-section'><div class='show-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo.jpg'></a></div><div class='hide-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo_mobile.jpg'></a></div></div></div></td></tr>##g" "$pathToData"dl.acm.org/pubs/lib/js/divTab.js

mv "$pathToData"dl.acm.org/pubs/lib/js/MathJax\?config\=TeX-AMS_CHTML "$pathToData"dl.acm.org/pubs/lib/js/MathJax.TeX-AMS_CHTML.js

for html in $(find ../data/delivery.acm.org/ -name '*html' -type f) ; do

  echo "---"
  echo "Processing $html"

  doi=$(sed -n "s,.*[\"']https://doi.org/\([^\"']*\).*,\1,p;q" $html)

  echo "doi: $doi"
  dest="$pathToDoi"/$doi/index.html
  echo "Saving to $dest"
  mkdir -p $(dirname "$dest")
  cp  $html $dest
  # -file $pathToLog/something.txt
  #tidy --drop-empty-elements no -indent $html > $dest || true

  filename=$(echo "$html" | sed -r 's#&#&amp;#g')
  echo "Fixing image links"
  sed -i 's#http://deliveryimages.acm.org/#../../../data/deliveryimages.acm.org/#g' "$dest"
  sed -i 's#https://dl.acm.org/pubs/lib/css/#../../../data/dl.acm.org/pubs/lib/css/#g' "$dest"
  sed -i 's#https://dl.acm.org/pubs/lib/js/#../../../data/dl.acm.org/pubs/lib/js/#g' "$dest"
  sed -i 's#https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js[?]config[=]TeX-AMS_CHTML#../../../data/dl.acm.org/pubs/lib/js/MathJax.TeX-AMS_CHTML.js#g' "$dest"

done
