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

def main(crossref=None, permalink=None, debug=False, *args):
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
    title = find_title(doc)

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
    print("""<p resource="https://doi.org/%s" vocab="http://schema.org/" typeof="Article">
        <div>
        <span property="author">%s</span>
      (<span class="year" property="datePublished">%s</span>):
    </div>
    <a href="doi/%s/" property="sameAs">
      <strong resource="https://doi.org/%s" class="title" property="name">%s</strong>
    </a>
    <div property="isPartOf" typeof="PublicationIssue"><em property="name">%s</em>
    </div>
    <div>
      <div>doi: <a href="https://doi.org/%s">%s</a></div>
      <div>Permalink: <a href="%s" property='sameAs'>%s</a></div>
    </div>
</p>""" % (doi, ", ".join(authors), year, doi, doi, title, proceeding, doi, doi, permalink, permalink))




def embed_html(doi, title, authors, year):
    print("""<p resource="https://doi.org/%s" vocab="http://schema.org/">
    <div>
        <span property="author">%s</span>
      (<span class="year" property="datePublished">%s</span>):
    </div>
      <strong class="title" property="name">%s</strong> 
</p>""" % (doi, ", ".join(authors), year, title))


if __name__ == "__main__":
    if "-h" in sys.argv:
        help()
        sys.exit(0)
    try:
        i = main(*sys.argv[1:])
        if i:
            print(sys.argv, file=sys.stderr)
    except Exception as e:
        print(sys.argv, file=sys.stderr)
        raise e
    sys.exit(i)
