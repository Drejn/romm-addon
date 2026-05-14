#!/usr/bin/env bash
set -e
echo "=== RUN.SH DEBUG START ==="
echo "Date: $(date)"
echo "BASE_PATH='${BASE_PATH:-{{ base_path }}}'"

echo "--- Environment ---"
env | sort

echo "--- Python info ---"
which python || true
python --version || true
echo "sys.executable and sys.path:"
python - <<'PY'
import sys, pkgutil
print("executable:", sys.executable)
print("sys.path:")
for p in sys.path:
    print("  ", p)
loader = pkgutil.find_loader("romm")
print("pkgutil.find_loader('romm') ->", loader)
try:
    import romm
    print("romm module location:", romm.__file__)
except Exception as e:
    print("import romm failed:", repr(e))
PY

echo "--- Files in /app and /usr/local ---"
ls -la /app || true
ls -la /usr/local || true

echo "--- Final exec ---"
exec python -m romm
