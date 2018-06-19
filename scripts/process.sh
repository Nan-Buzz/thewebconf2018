#!/bin/bash

set -e

title="Proceedings of the 2018 World Wide Web Conference"
src="https://www2018.thewebconf.org/proceedings/"
pathToData="../data/"
pathToDoi="../doi"
toc="../index.html"
pathToLog="$pathToData"log/
# rm -rf "$pathToData"
mkdir -p "$pathToData" "$pathToLog"

sed -i "s#<tr><td><div class='utilities-area'><div class='logo-section'><div class='show-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo.jpg'></a></div><div class='hide-for-large-up'><a class='navbar-brand'> <img alt='ACM Logo' class='img-responsive' src='https://dl.acm.org/pubs/lib/images/acm_logo_mobile.jpg'></a></div></div></div></td></tr>##g" "$pathToData"dl.acm.org/pubs/lib/js/divTab.js

#mv "$pathToData"dl.acm.org/pubs/lib/js/MathJax\?config\=TeX-AMS_CHTML "$pathToData"dl.acm.org/pubs/lib/js/MathJax.TeX-AMS_CHTML.js

rm -f $toc
echo "<DOCTYPE html>" >> $toc
echo "<html lang='en'>" >> $toc
echo "<head>" >> $toc
echo "  <meta charset='utf-8'>" >> $toc
echo "  <title>$title</title>" >> $toc
echo "</head>" >> $toc
echo "<body>" >> $toc
echo "  <banner>" >> $toc
echo "   <h1>$title</h1>" >> $toc

  echo "This is a web copy of <a href='$src'>$title</a> " >> $toc
  echo "originally published by ACM Press, " >>$toc
  echo "redistributed under the terms of " >> $toc
  echo "<a href='https://creativecommons.org/licenses/by/4.0/'>Creative Commons Attribution 4.0 (CC BY 4.0)</a>." >> $toc
  echo "The <a href='https://github.com/usable-oa/thewebconf2018/tree/master/scripts'>modifications</a> " >> $toc
  echo "from the originals are solely to improve HTML aiming to make it Findable, Accessible, Interoperable and Reusable. " >> $toc
  echo "augmenting HTML metadata and avoiding ACM trademark." >> $toc
  echo "To cite these papers, use their DOI." >> $toc
  echo "To link to or reference their HTML version here, use the corresponding w3id.org permalinks." >> $toc
echo "  </banner>" >> $toc
echo "  <main>" >> $toc


for html in $(find ../data/delivery.acm.org/ -name '*html' -type f) ; do
  echo "---"
  echo "Processing $html"

  # Fix some HTML syntax errors
  src=$(tempfile -s .html)
  cp $html $src
  sed -i 's,DOCTYPE html> html<html,DOCTYPE html><html,' $src
  sed -i 's,DOCTYPE html> htmlhtml<html,DOCTYPE html><html,' $src
  ## I mean.. how did this happen?
  sed -i 's,DOCTYPE html> htmlhtmlhtmlhtmlhtmlhtml<html,DOCTYPE html><html,' $src

  # Various tags that are not in HTML..
  for span in Affiliation1 Affiliation CopyrightStatement SmallCap SubTitle ; do 
      sed -i 's,<$span,<span,g' $src 
      sed -i 's,</$span,</span,g' $src  
  done
  for div in Footnote Appendix Quote; do
      sed -i 's,<$div,<div,g' $src  
      sed -i 's,</$div,</div,g' $src  
  done
  

  name=$(basename $html)
  case "$name" in 
    # Hard-coded exceptions as they for whatever reason won't match
    # doi regex below
    "p1749-thompson.html") doi="10.1145/3184558.3191636";;
    "p753-youngmann.html") doi="10.1145/3178876.3186156";;
    "p721-veen.html") doi="10.1145/3184558.3185978";;
    "p409-yoon.html") doi="10.1145/3178876.3186107";;    
    "p659-kusmierczyk.html") doi="10.1145/3178876.3186147";;
    "p1369-karypis.html") doi="10.1145/3184558.3191588";;
    "p433-szekely.html") doi="10.1145/3184558.3186203";; 
    *) 
      # The rest should match this pattern
      # assume a self-DOI at the very bottom under ACM's 10.1145/ tree
      # and a sub-id of 123.456
      doi=$(sed -n "s,.*[\"']https://doi.org/\(10.1145\/[0-9][0-9]*\.[0-9][0-9]*\).*,\1,p;q" $src)
  esac
  doilink="https://doi.org/$doi"
  permalink="https://w3id.org/oa/$doi"

  if [[ -z $doi ]] ; then
    echo "Can't find DOI of $html" >&2;
    exit;
  fi
  
  echo "doi: $doi"

  dest="$pathToDoi"/$doi/index.html
  mkdir -p $(dirname "$dest")
  json="$pathToDoi"/$doi/crossref.json

  crossreflog="$pathToLog"/$(echo $doi | sed s,/,_,g).crossref.log
  if [ ! -f $json ] ; then
    # FIXME: should really be in get.sh, but that does not know how 
    # to find DOI
    echo Fetching crossref metadata for $doi
    wget --output-file=$crossreflog -O $json https://api.crossref.org/v1/works/http://dx.doi.org/$doi &
  fi

  echo "Saving HTML to $dest"
  tidylogfile="$pathToLog"/$(echo $doi | sed s,/,_,g).tidy.log
  echo "Tidying HTML"
  #Make sure you install from https://github.com/htacg/tidy-html5

  tidy -quiet -file "$tidylogfile" --custom-tags inline --drop-empty-elements no -indent $src > $dest || (
    # Exit code 1 is just warnings, which we can ignore
    if [ $? -ne 1 ]; then 
      echo "tidy failed, copying HTML as-is" >>$tidylogfile
      echo "tidy failed, copying HTML as-is" >&2
      cp $src $dest
    fi;
  )


  # Let any crossref finish before we process the JSON
  wait
  ./crossref.py $json $permalink >> $toc
  
  echo "Fixing image links"
  sed -i 's#http://deliveryimages.acm.org/#../../../data/deliveryimages.acm.org/#g' "$dest"
  sed -i 's#https://dl.acm.org/pubs/lib/css/#../../../data/dl.acm.org/pubs/lib/css/#g' "$dest"
  sed -i 's#https://dl.acm.org/pubs/lib/js/#../../../data/dl.acm.org/pubs/lib/js/#g' "$dest"
  # This does not really work.. leave at official CDN for now  
  #sed -i 's#https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js[?]config[=]TeX-AMS_CHTML#../../../data/dl.acm.org/pubs/lib/js/MathJax.TeX-AMS_CHTML.js#g' "$dest"

  ## Add required we-modified-it-blurb (From CC-BY) as well as permalink
  
  blurb=$(tempfile)
  echo "<div>" >> $blurb
  echo "<p style='font-size: 75%; color #444'>" >> $blurb
  echo "This is a web copy of <a href='$doilink'>$doilink</a> " >> $blurb
  echo "originally published by ACM Press, " >>$blurb
  echo "redistributed under the terms of " >> $blurb
  echo "<a href='https://creativecommons.org/licenses/by/4.0/'>Creative Commons Attribution 4.0 (CC BY 4.0)</a>." >> $blurb
  echo "The <a href='https://github.com/usable-oa/thewebconf2018/tree/master/scripts'>modifications</a> " >> $blurb
  echo "from the original are solely to improve HTML aiming to make it Findable, Accessible, Interoperable and Reusable. " >> $blurb
  echo "augmenting HTML metadata and avoiding ACM trademark." >> $blurb  
  echo "To reference this HTML version, use:" >> $blurb
  echo "</p><p>" >> $blurb
  echo "<strong>Permalink:</strong>" >> $blurb
  echo "<a href='$permalink'>$permalink</a>" >> $blurb
  echo "</p></div>" >> $blurb
  echo "<hr>" >> $blurb

  ## First ensure there is a new line so we don't loose antyhing after the tag
  sed -i 's/body id="main">/&\n\n/' "$dest"
  # Then read in the blurb file below (need to use "" w/escapes to use $blurb)
  sed -i "/body id=\"main\">/ r $blurb" "$dest"


done

echo "  </main>" >> $toc
echo "</body>" >> $toc
echo "</html>" >> $toc
