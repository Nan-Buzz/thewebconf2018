#!/bin/bash

set -e

pathToData="../data/"
pathToDoi="../doi"
pathToLog="$pathToData"log/
# rm -rf "$pathToData"
mkdir -p "$pathToData" "$pathToLog"

sed -i "s#<tr><td><div class='utilities-area'><div class='logo-section'><div class='show-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo.jpg'></a></div><div class='hide-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo_mobile.jpg'></a></div></div></div></td></tr>##g" "$pathToData"dl.acm.org/pubs/lib/js/divTab.js

#mv "$pathToData"dl.acm.org/pubs/lib/js/MathJax\?config\=TeX-AMS_CHTML "$pathToData"dl.acm.org/pubs/lib/js/MathJax.TeX-AMS_CHTML.js

for html in $(find ../data/delivery.acm.org/ -name '*html' -type f) ; do

  echo "---"
  echo "Processing $html"

  # assume a self-DOI at the very bottom under ACM's 10.1145/ tree
  # and a sub-id of 123.456 or 123

  name=$(basename $html)
  case "$name" in 
    # Hard-coded exceptions as they for whatever reason won't match
    # regex below
    "p1749-thompson.html") doi="10.1145/3184558.3191636";;
    "p753-youngmann.html") doi="10.1145/3178876.3186156";;
    "p721-veen.html") doi="10.1145/3184558.3185978";;
    "p409-yoon.html") doi="10.1145/3178876.3186107";;    
    *) 
      # The rest should match this pattern
      doi=$(sed -n "s,.*[\"']https://doi.org/\(10.1145\/[0-9.]*\).*,\1,p;q" $html)
  esac

  if [[ -z $doi ]] ; then
    echo "Can't find DOI of $html" >&2;
    exit;
  fi
  
  echo "doi: $doi"

  echo Fetching crossref metadata for $doi
  json="$pathToDoi"/$doi/crossref.json
  wget -q -O $json https://api.crossref.org/v1/works/http://dx.doi.org/$doi &


  dest="$pathToDoi"/$doi/index.html
  echo "Saving HTML to $dest"
  mkdir -p $(dirname "$dest")

  logfile="$pathToLog"/$(echo $doi | sed s,/,_,g).tidy.log
  echo "Tidying HTML"
  #Make sure you install from https://github.com/htacg/tidy-html5

  tidy -quiet -file "$logfile" --drop-empty-elements no -indent $html > $dest || (
    # Exit code 1 is just warnings, which we can ignore
    if [ $? -ne 1 ]; then 
      echo "tidy failed, copying HTML as-is" >$logfile
      echo "tidy failed, copying HTML as-is" >&2
      cp $html $dest
    fi;
  )

  wait
  filename=$(echo "$html" | sed -r 's#&#&amp;#g')
  echo "Fixing image links"
  sed -i 's#http://deliveryimages.acm.org/#../../../data/deliveryimages.acm.org/#g' "$dest"
  sed -i 's#https://dl.acm.org/pubs/lib/css/#../../../data/dl.acm.org/pubs/lib/css/#g' "$dest"
  sed -i 's#https://dl.acm.org/pubs/lib/js/#../../../data/dl.acm.org/pubs/lib/js/#g' "$dest"
  # This does not really work.. leave at official CDN for now  
  #sed -i 's#https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js[?]config[=]TeX-AMS_CHTML#../../../data/dl.acm.org/pubs/lib/js/MathJax.TeX-AMS_CHTML.js#g' "$dest"

done
