#!/usr/bin/env python3
import sys
import json

def help():
    print("""crossref.py [crossref] [permalink] [-d]")

Extract authorship and title from crossref JSON

If parameter [crossref] is supplied. it is assumed to be a file path
to a JSON file from the crossref API.

If the parameter is missing or -, the JSON is read from stdin.

Output on stdout is schema.org-annotated HTML5+RDFa that can be included 
in the top of the corresponding article HTML.

If the parameter [permalink] is provided, it will be assumed to be
a hyperlink to the HTML article (as part of a listing). 
In this case the output will also include additional 
information such as DOI and proceedings.

If the parameter -d is provided, the parsed JSON is output with 
pretty-printing instead of the HTML.

""")

htmlTemplate = """
<!DOCTYPE html>
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8" />
    <title>${title}</title>
  </head>
  <body vocab="http://schema.org/">
    <header>
      <h1>${title}</h1>
      <p>This is a web copy of <a property="mainEntityOfPage http://purl.org/pav/derivedFrom http://www.w3.org/ns/prov#wasDerivedFrom" href="{$src}"><span property="name">${title}</span></a>.
 Published in WWW2018 Proceedings © 2018 International World Wide Web Conference Committee, published under
 <a rel="license" property="license" href="https://creativecommons.org/licenses/by/4.0/">
 Creative Commons CC By 4.0 License</a>.</p>
      <p>The <a property="http://purl.org/pav/createdWith" typeof="SoftwareSourceCode" href="https://github.com/usable-oa/thewebconf2018/tree/master/scripts">modifications</a> from the originals are solely to improve HTML aiming to make them <a href="https://doi.org/10.1038/sdata.2016.18" property="publishingPrinciples">Findable, Accessible, Interoperable and Reusable</a>, augmenting metadata and (just in case) avoiding ACM trademarks. To help improve this, please <a property="discussionUrl" href="https://github.com/usable-oa/thewebconf2018/issues">raise an issue or pull request</a>.</p>
      <p>To cite these papers, use their DOI. To link to or reference their HTML version here, use the corresponding w3id.org permalinks.</p>
    </header>
    <main>
      <ul rel="hasPart">
      ${parts}
      </ul>
    </main>
  </body>
</html>
"""

    


def crossref(crossref=None, permalink=None, debug=False):
    if crossref is None or crossref == "-":
        # Always read JSON as UTF-8 even if system encoding differs
        f = TextIOWrapper(sys.stdin, encoding="utf-8")
    else:
        f = open(crossref, encoding="utf-8")
    j = json.load(f)
    if not j["status"] == "ok":
        print("Error in CrossRef JSON, did API call fail?", file=sys.stderr)
        return 1
    doc = j["message"]

    doi = find_doi(doc)
    authors = find_authors(doc)
    year = find_year(doc)
    title = escape_html(find_title(doc))

    if "-d" in args or permalink == "-d":
        json.dump(j, sys.stdout, sort_keys=True, indent=2)
    elif permalink:
        listing_html(doi, title, authors, year, permalink, find_proceeding(doc))
    else:
        embed_html(doi, title, authors, year)
    return 0

def find_doi(doc):
    return doc["DOI"]

def find_proceeding(doc):
    # TODO: What if there isn't any?
    return doc["container-title"][0]

def find_authors(doc):
    auths = []
    for a in doc["author"]:
        # FIXME: Should be name order agnostic
        auths.append("%s %s" % (a["given"], a["family"]))
    return auths

def find_year(doc):
    return doc["issued"]["date-parts"][0][0]

def find_title(doc):
    t = doc["title"][0]
    # TODO: Check [1] and "subtitle" ?
    return t

def listing_html(doi, title, authors, year, permalink, proceeding):
    print("""  <li about="%s" id="%s" typeof="ScholarlyArticle">
    <a href="doi/%s/" property="name">%s</a>
    <dl>
      <dt>Authors</dt>
      <dd xml:lang="" lang="">%s</dd>
      <dt>DOI</dt>
      <dd><a href="https://doi.org/%s" property="sameAs">%s</a></dd>
      <dt>Permalink</dt>
      <dd><a href="%s">%s</a></dd>
    </dl>
  </li>""" % (permalink, doi, doi, title, ", ".join(authors), doi, doi, permalink, permalink))


def escape_html(t):
    """HTML-escape the text in `t`."""
    return (t
        .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        .replace("'", "&#39;").replace('"', "&quot;")
        )

def main(folder="./doi/"):
    # TODO: 
    # 1. Loop over folder to run crossref()
    # 2. Group by proceedings
    # 3. Sort by DOI
    # 4. Output using htmlTemplate
    pass    

if __name__ == "__main__":
    if "-h" in sys.argv:
        help()
        sys.exit(0)
    i = main(*sys.argv[1:])
    sys.exit(i)
