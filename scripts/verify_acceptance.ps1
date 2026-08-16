param(
  [string]$MoonBitBin,
  [switch]$SkipRemote,
  [switch]$SkipMooncakes
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not [string]::IsNullOrWhiteSpace($MoonBitBin)) {
  $resolvedMoonBitBin = (Resolve-Path -LiteralPath $MoonBitBin -ErrorAction Stop).Path
  foreach ($tool in @("moon.exe", "moonc.exe", "moonrun.exe")) {
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedMoonBitBin $tool))) {
      throw "MoonBit toolchain is incomplete: missing $tool in $resolvedMoonBitBin"
    }
  }
  $env:Path = $resolvedMoonBitBin + ";" + $env:Path
}

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
Require-File "src/native/parallel_wave.mbt"
Require-File "src/benchmark.mbt"
Require-File "src/plan_analysis.mbt"
Require-File "src/validation.mbt"
Require-File "src/diagnostics.mbt"
Require-File "src/native_stub.c"
Require-File ".github/workflows/test.yml"
Require-File "examples/sample.build.ninja"
Require-File "examples/benchmarks/medium.build.ninja"
Require-File "examples/benchmarks/large.build.ninja"
Require-File "examples/fixtures/hello.c"
Require-File "examples/fixtures/math.c"
Require-File "examples/fixtures/math.h"
Require-File "examples/fixtures/strings.c"
Require-File "examples/fixtures/config.h"
Require-File "examples/fixtures/parser.c"
Require-File "examples/fixtures/codec.c"
Require-File "source-attribution.md"
Require-File "submission-status.md"
Require-File "CHANGELOG.md"
Require-File "docs/acceptance/final-checklist.md"

$readme = Get-Content -Raw README.md
$workflow = Get-Content -Raw .github/workflows/test.yml
Add-Check "README mentions Mooncakes" ($readme -match "Mooncakes") "README should explain publication metadata"
Add-Check "README mentions CI" ($readme -match "\bCI\b") "README should point to automated verification"
Add-Check "README mentions incremental" ($readme -match "incremental") "README should describe the core implementation path"
Add-Check "README mentions SCC" ($readme -match "Tarjan|SCC") "README should describe cyclic graph handling"
Add-Check "README mentions MTime/hash" ($readme -match "MTime.*hash|hash.*MTime") "README should describe real file identity"
Add-Check "README mentions WASM host" ($readme -match "moon_ninja\.execute_command") "README should document the WASM host ABI"
Add-Check "README references Ninja and n2" ($readme -match "ninja-build/ninja" -and $readme -match "evmar/n2") "README should identify compatibility references"
Add-Check "README mentions benchmark fixtures" ($readme -match "medium\.build\.ninja" -and $readme -match "2,500") "README should document committed workload evidence"
Add-Check "README mentions boundary tests" ($readme -match "boundary" -and $readme -match "order-only") "README should document edge coverage"
Add-Check "README mentions portable tooling" ($readme -match "depfile" -and $readme -match "response") "README should document practical build-tool APIs"
Add-Check "README has no unfinished checklist" (-not ($readme -match "- \[ \]")) "README completion checklist must be closed out"
Add-Check "CI targets canonical GitHub branch" ($workflow -match "branches:\s*\r?\n\s*-\s*main" -and $workflow -notmatch '\$default-branch') "CI must trigger on main"
Add-Check "CI checks MoonBit 0.10.7" ($workflow -match "0\.10\.7") "CI must verify the latest toolchain"

$modContent = Get-Content -Raw moon.mod
Add-Check "moon.mod repository" ($modContent -match 'repository = "') "repository metadata present"
Add-Check "moon.mod readme" ($modContent -match 'readme = "README.md"') "readme metadata present"
Add-Check "moon.mod license" ($modContent -match 'license = "Apache-2.0"') "license metadata present"

$commitCount = [int](git rev-list --count HEAD)
Add-Check "commit history" ($commitCount -ge 10) "commit count = $commitCount"

$sourceLines = git ls-files '*.mbt' '*.mbti' '*.c' '*.h' | ForEach-Object {
  (Get-Content $_).Count
} | Measure-Object -Sum | Select-Object -ExpandProperty Sum
Add-Check "MoonBit/C source scale" ($sourceLines -gt 4000) "tracked .mbt/.mbti/.c/.h lines = $sourceLines"

Invoke-Checked "moon fmt --check" "moon fmt --check"
 $toolchainText = (moon version --all | Out-String)
Add-Check "MoonBit 0.10.7 local toolchain" ($toolchainText -match "0\.10\.7") "moon version --all contains 0.10.7"
if ($toolchainText -notmatch "0\.10\.7") {
  throw "MoonBit 0.10.7 is required for acceptance verification"
}
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
