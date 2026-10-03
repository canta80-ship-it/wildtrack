import json, os, time, urllib.request
url = 'https://api.github.com/repos/' + os.environ['GITHUB_REPOSITORY'] + '/actions/workflows/build-apk.yml/runs?branch=' + os.environ['GITHUB_REF_NAME'] + '&per_page=20'
for attempt in range(90):
    request = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + os.environ['GITHUB_TOKEN'], 'Accept': 'application/vnd.github+json'})
    with urllib.request.urlopen(request) as response:
        runs = json.load(response)['workflow_runs']
    run = next((r for r in runs if r['head_sha'] == os.environ['GITHUB_SHA']), None)
    if run and run['status'] == 'completed':
        if run['conclusion'] != 'success':
            raise SystemExit('APK build did not succeed: ' + str(run['conclusion']))
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.write('run_id=' + str(run['id']) + '\n')
        print('Testing APK from current commit', os.environ['GITHUB_SHA'])
        break
    print('Waiting for current-commit signed APK', flush=True)
    time.sleep(10)
else:
    raise SystemExit('Timed out waiting for current-commit APK')

