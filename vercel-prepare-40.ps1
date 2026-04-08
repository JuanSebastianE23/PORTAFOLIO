<#
vercel-prepare-40.ps1
Crea una rama nueva y realiza 40 commits locales, cada commit agrega un archivo
secuencial dentro de vercel-setup/ describiendo pasos y archivos para preparar
el repo para desplegar en Vercel.

Ejecútalo desde la raíz del repo en PowerShell.
#>

param(
    [int]$Commits = 40
)

# Ensure git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error 'Git no está instalado o no está en PATH.'; exit 1
}

$root = (& git rev-parse --show-toplevel) 2>$null
if (-not $?) { Write-Error 'No es un repositorio git.'; exit 1 }
Set-Location $root

# Check working tree cleanliness; allow untracked but abort if staged changes
$porcelain = & git status --porcelain
if ($porcelain -match '^[ MADRCU]') {
    Write-Host 'Hay cambios staged o modificados en el working tree. Por seguridad, limpia o stash tus cambios antes de ejecutar este script.' -ForegroundColor Yellow
    exit 1
}

$ts = (Get-Date).ToString('yyyyMMddHHmmss')
$branch = "vercel/prepare-$ts"
Write-Host "Creando y cambiando a rama: $branch"
& git switch -c $branch || { Write-Error 'No se pudo crear la rama.'; exit 1 }

$dir = Join-Path $root 'vercel-setup'
if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory | Out-Null }

# Create a small vercel.json as first commit
$vercelJson = @'
{
  "version": 2,
  "builds": [
    { "src": "package.json", "use": "@vercel/static-build" }
  ],
  "routes": [
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
'@
Set-Content -Path (Join-Path $dir '01-vercel.json') -Value $vercelJson -Encoding UTF8
& git add -- (Join-Path $dir '01-vercel.json')
& git commit -m "subiendo archivos de mi portafolio - vercel json"
Write-Host "Commit 1: vercel json"

# Create .vercelignore as 2nd commit
$ignore = @'
node_modules
.vscode
.env
*.log
'@
Set-Content -Path (Join-Path $dir '02-.vercelignore') -Value $ignore -Encoding UTF8
& git add -- (Join-Path $dir '02-.vercelignore')
& git commit -m "subiendo archivos de mi portafolio - vercel ignore"
Write-Host "Commit 2: vercel ignore"

# Create env example
$env = @'
# Ejemplo de variables de entorno para Vercel
NEXT_PUBLIC_API_URL=https://api.example.com
'@
Set-Content -Path (Join-Path $dir '03-env.example') -Value $env -Encoding UTF8
& git add -- (Join-Path $dir '03-env.example')
& git commit -m "subiendo archivos de mi portafolio - env example"
Write-Host "Commit 3: env example"

# Create README for Vercel steps
$readme = @'
Guía rápida para desplegar en Vercel:
1. Asegúrate de tener script de build en package.json: "build": "vite build" o el que corresponda.
2. Configura variables de entorno en Vercel.
3. Añade vercel.json y .vercelignore.
4. Conecta el repo desde Vercel y selecciona la rama de deploy.
'@
Set-Content -Path (Join-Path $dir '04-README-vercel.md') -Value $readme -Encoding UTF8
& git add -- (Join-Path $dir '04-README-vercel.md')
& git commit -m "subiendo archivos de mi portafolio - README vercel"
Write-Host "Commit 4: README vercel"

# Remaining commits: create step files 05..40
for ($i = 5; $i -le $Commits; $i++) {
    $num = "{0:00}" -f $i
    $file = Join-Path $dir ("$num-step.md")
    $content = "# Paso $i`n`nDescripción: Acción sugerida para preparar el repo para Vercel.`nFecha: $(Get-Date -Format o)`n"
    Add-Content -Path $file -Value $content -Encoding UTF8
    & git add -- $file
    & git commit -m "subiendo archivos de mi portafolio - paso $i"
    Write-Host "Commit $i: creado $file"
}

Write-Host "Creación completa de $Commits commits en la rama $branch" -ForegroundColor Green
& git --no-pager log --oneline -n $Commits

Write-Host "Para subir al remoto ejecuta: git push -u origin $branch" -ForegroundColor Yellow
