# Runs every test (t*.py), each in its own Lua runtime; the output of each
# in tests/out/<test>.txt, one line each here. Exit code 1 if any fails.
#   D:\Dev\ControllerKeyboard-tests\venv\Scripts\python.exe tests\run_all.py
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)
env = dict(os.environ, PYTHONIOENCODING="utf-8")
failed = 0
for t in sorted(n for n in os.listdir(HERE) if n.startswith("t") and n.endswith(".py")):
    out = os.path.join(OUT, t.replace(".py", ".txt"))
    with open(out, "w", encoding="utf-8") as f:
        r = subprocess.run([sys.executable, os.path.join(HERE, t)], stdout=f, stderr=subprocess.STDOUT, cwd=HERE, env=env)
    lines = open(out, encoding="utf-8", errors="replace").read().splitlines()
    checks = sum(1 for l in lines if l.startswith("  ok ") or l.startswith("  FAIL "))
    fails = [l for l in lines if l.startswith("fails:")]
    errors = [l for l in lines if l.startswith("errors:")]
    end = (fails[-1] + "  " + errors[-1]) if fails and errors else "NO END (crashed?)"
    if r.returncode != 0:
        failed += 1
    print(f"{t:22s} {'ok  ' if r.returncode == 0 else 'FAIL'} checks={checks:3d}  {end}")
    if r.returncode != 0:
        for l in lines:
            if l.startswith("  FAIL ") or "ERR" in l or l.startswith("LOAD") or l.startswith("Traceback"):
                print("    " + l.strip())
print("all passed" if failed == 0 else f"{failed} test file(s) failed")
sys.exit(1 if failed else 0)
