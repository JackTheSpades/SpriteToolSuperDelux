import requests
from contextlib import suppress
import os
import json
import zipfile

types = {
    'standard': (46, 17),
    'shooter': (47, 1),
    'generator': (48, 1),
    'cluster': (64, 1),
    'extended': (65, 1),
}

def _get_pagecount(name):
    _, expectedpages = types[name]
    uri = f'https://www.smwcentral.net/ajax.php?a=getsectionlist&s=smwsprites&f[tool][]=pixi&f[type][]={name}'
    with requests.get(uri) as res:
        response = res.json()
    return response.get('last_page', expectedpages)

def _download():
    with requests.Session() as sess:
        for name, _ in types.items():
            with suppress(Exception):
                os.mkdir(name)
            nameids = {}
            pages = _get_pagecount(name)
            for page in range(pages):
                uri = f'https://www.smwcentral.net/ajax.php?a=getsectionlist&s=smwsprites&u=0&g=0&n={page + 1}' \
                      f'&o=date&d=desc&f[tool][]=pixi&f[type][]={name}'
                with sess.get(uri) as res:
                    response = res.json()
                objects = response['data']
                print(f"Downloading {name} sprites page {page + 1} of {pages} ({len(objects)} sprites)")
                for obj in objects:
                    link = obj['download_url']
                    submission_id = obj['id']
                    sublink = f'https://www.smwcentral.net/?p=section&a=details&id={submission_id}'
                    spritename = obj['name']
                    nameids[sublink] = [submission_id, spritename]
                    with sess.get(link) as res:
                        if res.status_code != 200:
                            del nameids[sublink]
                            with open(f'{name}/{submission_id}_error.html', 'wb') as p:
                                p.write(res.content)
                        else:
                            with open(f'{name}/{submission_id}.zip', 'wb') as p:
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
