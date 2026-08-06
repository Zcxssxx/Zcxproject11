param(
  [switch]$SkipRemote,
  [switch]$SkipMooncakes
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Name,
    [bool]$Passed,
    [string]$Detail
  )
  $checks.Add([pscustomobject]@{
      Name = $Name
      Passed = $Passed
      Detail = $Detail
    })
}

function Require-File {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    Add-Check "file:$Path" $true "present"
  } else {
    Add-Check "file:$Path" $false "missing"
  }
}

function Invoke-Checked {
  param(
    [string]$Name,
    [string]$Command
  )
  Invoke-Expression $Command | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Add-Check $Name $false "command failed: $Command"
    throw "$Name failed"
  }
  Add-Check $Name $true "passed"
}

Require-File "README.md"
Require-File "LICENSE"
Require-File "moon.mod"
Require-File "src/moon.pkg"
Require-File "src/main/moon.pkg"
Require-File "src/fingerprint.mbt"
Require-File "src/wave_executor.mbt"
Require-File "src/native/native_stub.c"
Require-File ".github/workflows/test.yml"
Require-File "examples/sample.build.ninja"
Require-File "source-attribution.md"
Require-File "submission-status.md"

$readme = Get-Content -Raw README.md
Add-Check "README mentions Mooncakes" ($readme -match "Mooncakes") "README should explain publication metadata"
Add-Check "README mentions CI" ($readme -match "\bCI\b") "README should point to automated verification"
Add-Check "README mentions incremental" ($readme -match "incremental") "README should describe the core implementation path"
Add-Check "README mentions SCC" ($readme -match "Tarjan|SCC") "README should describe cyclic graph handling"
Add-Check "README mentions MTime/hash" ($readme -match "MTime.*hash|hash.*MTime") "README should describe real file identity"
Add-Check "README mentions WASM host" ($readme -match "moon_ninja\.execute_command") "README should document the WASM host ABI"
Add-Check "README references Ninja and n2" ($readme -match "ninja-build/ninja" -and $readme -match "evmar/n2") "README should identify compatibility references"

$modContent = Get-Content -Raw moon.mod
Add-Check "moon.mod repository" ($modContent -match 'repository = "') "repository metadata present"
Add-Check "moon.mod readme" ($modContent -match 'readme = "README.md"') "readme metadata present"
Add-Check "moon.mod license" ($modContent -match 'license = "Apache-2.0"') "license metadata present"

$commitCount = [int](git rev-list --count HEAD)
Add-Check "commit history" ($commitCount -ge 10) "commit count = $commitCount"

$sourceLines = git ls-files '*.mbt' '*.mbti' | ForEach-Object {
  (Get-Content $_).Count
} | Measure-Object -Sum | Select-Object -ExpandProperty Sum
Add-Check "MoonBit source scale" ($sourceLines -ge 250) "tracked .mbt/.mbti lines = $sourceLines"

Invoke-Checked "moon fmt --check" "moon fmt --check"
Invoke-Checked "moon check --deny-warn" "moon check --deny-warn"
Invoke-Checked "moon check --target all --deny-warn" "moon check --target all --deny-warn"
Invoke-Checked "moon test --deny-warn" "moon test --deny-warn"

$compiler = Get-Command cl,gcc,clang,cc -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $compiler) {
  Invoke-Checked "moon build --target all --deny-warn" "moon build --target all --deny-warn"
  Invoke-Checked "moon test --target all --deny-warn" "moon test --target all --deny-warn"
  Invoke-Expression "moon test --deny-warn --target native" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Add-Check "moon test --deny-warn --target native" $false "native target failed with $($compiler.Name)"
    throw "moon test --deny-warn --target native failed"
  }
  Add-Check "moon test --deny-warn --target native" $true "passed with $($compiler.Name)"
} else {
  Invoke-Checked "moon build --target wasm-gc --deny-warn" "moon build --target wasm-gc --deny-warn"
  Invoke-Checked "moon build --target js --deny-warn" "moon build --target js --deny-warn"
  Invoke-Checked "moon test --target wasm-gc --deny-warn" "moon test --target wasm-gc --deny-warn"
  Invoke-Checked "moon test --target js --deny-warn" "moon test --target js --deny-warn"
  Add-Check "all-target build/test" $true "native build/test skipped locally: no system C compiler found, covered by CI"
  Add-Check "moon test --deny-warn --target native" $true "skipped locally: no system C compiler found, covered by CI"
}

$defaultBranch = git symbolic-ref --short refs/remotes/origin/HEAD 2>$null
Add-Check "remote default branch" (-not [string]::IsNullOrWhiteSpace($defaultBranch)) "origin HEAD = $defaultBranch"

if (-not $SkipRemote) {
  $originHead = git ls-remote --symref origin HEAD 2>$null
  Add-Check "remote HEAD visible" (-not [string]::IsNullOrWhiteSpace($originHead)) ($originHead | Select-Object -First 1)
}

if (-not $SkipMooncakes) {
  $whoami = ""
  try {
    $whoami = (moon whoami) -join "`n"
    Add-Check "moon whoami" $true $whoami.Trim()
  } catch {
    Add-Check "moon whoami" $false $_.Exception.Message
  }
}

$failed = @($checks | Where-Object { -not $_.Passed })
$checks | Format-Table -AutoSize

if ($failed.Count -gt 0) {
  throw "Acceptance verification failed with $($failed.Count) failing checks."
}

Write-Host ""
Write-Host "Acceptance verification passed."
