import mistune
from bs4 import BeautifulSoup
import re

htmlrenderer = mistune.create_markdown(
    escape=False,
    renderer='html',
    plugins=['url', 'strikethrough', 'footnotes', 'table'],
)

PRELUDE = """<!DOCTYPE html>
<meta charset="UTF-8">
<html>
<head>
    <style>
    body {
    font-family: sans-serif;
    margin: 0 auto;
    max-width: 960px;
    }
    </style>
</head>
<body>
"""
CLOSING = """  </body>
</html>"""

def mdtohtml(filename: str):
    with open(filename) as f:
        md = f.read()
        html = htmlrenderer(md)

    soup = BeautifulSoup(html, 'html.parser')

    for u in soup.find_all('a'):
        if u.get('href').endswith('.md'):
            u['href'] = u.get('href').replace('.md', '.html')

    pt = re.compile(r'[^\s\w-]')

    def heading_id(heading_txt):
        return pt.sub('', heading_txt.lower().replace(' ', '-'))

    for h2 in soup.find_all('h2'):
        h2['id'] = heading_id(h2.text)

    for h3 in soup.find_all('h3'):
        h3['id'] = heading_id(h3.text)

    with open(filename.replace('.md', '.html'), 'w') as f:
        f.write(PRELUDE)
        f.write(str(soup))
        f.write(CLOSING)

md_files = ['README.md', 'CHANGELOG.md', 'CONTRIBUTING.md']
for md_file in md_files:
    mdtohtml(md_file)

