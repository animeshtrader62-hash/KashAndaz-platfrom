Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$backendPath = "C:\KashAndaz platform\backend-worktree\backend"
Set-Location $backendPath

# Install deps (idempotent)
python -m pip install -r requirements.txt

# Run API
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
