import os, subprocess, tempfile, textwrap
from pathlib import Path
source=(Path(__file__).resolve().parents[1] / 'workflows/release.yml').read_text()
step=source.split('      - name: Publish appcast.xml to appcast branch',1)[1].split('      # Mint a 1-hour',1)[0]
script=textwrap.dedent(step.split('        run: |\n',1)[1]).replace('${{ steps.version.outputs.version }}','2.5.1')
for race in (False,True):
 with tempfile.TemporaryDirectory() as tmp:
  root=Path(tmp); repo=root/'repo'; repo.mkdir(); remote=root/'remote.git'; runner=root/'runner'; runner.mkdir(); mock=root/'bin';mock.mkdir()
  def run(*args,cwd=repo):
   return subprocess.run(args,cwd=cwd,text=True,capture_output=True,check=True).stdout
  run('git','init','--bare',str(remote))
  run('git','init','-b','appcast')
  run('git','config','user.name','Feed test'); run('git','config','user.email','feed@example.invalid')
  run('git','remote','add','origin',str(remote))
  (repo/'appcast.xml').write_text('old feed\n'); run('git','add','appcast.xml');run('git','commit','-m','old');run('git','push','origin','appcast')
  old=run('git','rev-parse','HEAD').strip()
  (runner/'appcast_current.xml').write_text('old feed\n')
  if race:
   (repo/'appcast.xml').write_text('concurrent feed\n');run('git','commit','-am','concurrent');run('git','push','origin','appcast')
  (repo/'appcast.xml').write_text('old feed\nnew item\n')
  (mock/'gh').write_text('#!/bin/sh\nexit 0\n');(mock/'gh').chmod(0o755)
  result=subprocess.run(['bash','-c',script],cwd=repo,env=dict(os.environ,RUNNER_TEMP=str(runner),PATH=str(mock)+':'+os.environ['PATH']),capture_output=True,text=True)
  assert (result.returncode==0)==(not race),(result.stdout,result.stderr)
  feed=run('git','--git-dir',str(remote),'show','appcast:appcast.xml')
  assert feed==('concurrent feed\n' if race else 'old feed\nnew item\n'),feed
  run('git','--git-dir',str(remote),'merge-base','--is-ancestor',old,'appcast')
  print('PASS: concurrent update rejected' if race else 'PASS: feed published with history preserved')
