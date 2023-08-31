import requests
from contextlib import suppress
from bs4 import BeautifulSoup
from urllib import parse
import os
import re
import json
import zipfile

types = {
    'standard': (46, 17),
    'shooter': (47, 1),
    'generator': (48, 1),
    'cluster': (64, 1),
    'extended': (65, 1),
}

def _getnum(pageno: str):
    try:
        return int(pageno)
    except ValueError:
        return -1

def _get_pagecount(name):
    spid, expectedpages = types[name]
    uri = f'https://www.smwcentral.net/?p=section&s=smwsprites&f[tool][]=142&f[type][]={spid}'
    with requests.get(uri) as res:
        soup = BeautifulSoup(res.text, 'html.parser')
    page_lists = soup.find_all('ul', attrs={'class': 'page-list'})
    if page_lists is None or len(page_lists) == 0:
        return expectedpages
    page_list = page_lists[0]
    pages = max(map(lambda li:  _getnum(li.text), page_list.find_all('li')))
    return pages

def _download():
    with requests.Session() as sess:
        for name, value in types.items():
            with suppress(Exception):
                os.mkdir(name)
            nameids = {}
            spid, _ = value
            pages = _get_pagecount(name)
            for page in range(pages):
                uri = f'https://www.smwcentral.net/?p=section&s=smwsprites&u=0&g=0&n={page + 1}' \
                      f'&o=date&d=desc&f%5Btool%5D%5B%5D=142&f%5Btype%5D%5B%5D={spid}'
                with sess.get(uri) as res:
                    soup = BeautifulSoup(res.text, 'html.parser')
                links = ['https:' + link['href'] for link in soup.find_all('a', href=re.compile('dl.smwcentral.net'))]
                print(f"Downloading {name} sprites page {page + 1} of {pages} ({len(links)} sprites)")
                for link in links:
                    submission_id = link.split('/')[-2]
                    sublink = 'https://www.smwcentral.net/?p=section&a=details&id=' + submission_id
                    spritename = link.split('/')[-1].rstrip('.zip')
                    nameids[sublink] = [int(submission_id), parse.unquote(spritename)]
                    with sess.get(link) as res:
                        if res.status_code != 200:
                            del nameids[sublink]
                            with open(name + '/' + submission_id + '_error.html', 'wb') as p:
                                p.write(res.content)
                        else:
                            with open(name + '/' + submission_id + '.zip', 'wb') as p:
                                p.write(res.content)
            with open(name + '/' + 'names.json', 'w') as f:
                f.write(json.dumps(nameids, indent=4))

def _download_if_smwc_failed():
    ATARISMWC_SPRITES_URL = "https://www.atarismwc.com/pixi_test_sprites.zip"
    with requests.Session() as sess:
        with sess.get(ATARISMWC_SPRITES_URL) as res:
            if res.status_code != 200:
                raise Exception("Failed to download sprites")
            with open('pixi_test_sprites.zip', 'wb') as p:
                p.write(res.content)
    with zipfile.ZipFile('pixi_test_sprites.zip') as z:
        z.extractall()
    os.remove('pixi_test_sprites.zip')


def download():
    print("Downloading sprites")
    try:
        _download()
        return False
    except requests.exceptions.RequestException as e:
        print(f'Download from SMWC failed because {str(e)}, using other source')
        _download_if_smwc_failed()
        return True

__all__ = ['download']

if __name__ == '__main__':
    download()
