import json
import zipfile
from zipfile import ZipFile

with open('result_current.json', 'r') as a, open('result_latest.json', 'r') as b, open('differences.json', 'r') as c:
    current = json.loads(a.read())
    latest = json.loads(b.read())
    diff = json.loads(c.read())

curr_succ = current['success']
lat_succ = latest['success']
curr_fail = current['error']
lat_fail = latest['error']

result = '```'

if len(curr_succ) != len(lat_succ):
    result += f'Different successes, current: {len(curr_succ)}, latest: {len(lat_succ)}\n'
else:
    result += 'Same number of successes\n'

if len(curr_fail) != len(lat_fail):
    result += f'Different fails, current: {len(curr_fail)}, latest: {len(lat_fail)}\n'
else:
    result += 'Same number of failures\n'

diff_bool = False
partial_res = ''
for n, d in diff.items():
    if 'different' in d.lower():
        diff_bool = True
        partial_res += f'Differences in {n}, {d}\n'

if len(partial_res) > 1000:
    partial_res = partial_res[:1000]

if not diff_bool:
    result += 'No differences in the ROM binary'

result += '```'

json_payload = {
    "embeds": [                      
        {                   
            "title": "Test result",
            "description": result
        }                 
    ]
}

with ZipFile('results.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    z.write('result_current.json')
    z.write('result_latest.json')
    z.write('differences.json')

