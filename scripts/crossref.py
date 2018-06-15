import sys
import json

def help():
    print("""crossref.py [crossref] [-d]")

Extract authorship and title from crossref JSON

If parameter [crossref] is supplied. it is assumed to be a file path
to a JSON file from the crossref API.

If the parameter is missing or -, the JSON is read from stdin.

Output on stdout is schema.org-annotated HTML5+RDFa that can be included 
in the top of the corresponding article HTML.

If the parameter -d is provided, the parsed JSON is output with 
pretty-printing instead of the HTML.
""")

def main(crossref=None, *args):
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
    if "-d" in args:
        json.dump(j, sys.stdout, sort_keys=True, indent=2)
    else:
        render_html(doi, title, authors, year)
    return 0

def find_doi(doc):
    return doc["DOI"]

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

def render_html(doi, title, authors, year):
    print("""<div about="https://doi.org/%s" namespace="http://schema.org/">
    <div>
        <span property="author">%s<span>
      (<span class="year" property="year">%s</span>):
    </div>
      <strong class="title" property="title">%s</strong> 
</div>""" % (doi, ", ".join(authors), year, title))


if __name__ == "__main__":
    if "-h" in sys.argv:
        help()
        sys.exit(0)
    i = main(*sys.argv[1:])
    sys.exit(i)
