$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root '.venv\Scripts\python.exe'

if (-not (Test-Path $python)) {
  python -m venv (Join-Path $root '.venv')
}

& $python -m pip install --upgrade pip
& $python -m pip install -r (Join-Path $PSScriptRoot 'requirements-midterm-aqs-pm25.txt')

# Install a kernelspec inside the project venv instead of writing to the user profile.
& $python -m ipykernel install --prefix (Join-Path $root '.venv') --name midterm-aqs-pm25 --display-name "Python (.venv) midterm-aqs-pm25"

Write-Host "Midterm AQS environment ready."
