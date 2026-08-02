# Build itch-hw bitstream (USE_ETH=1). Run from repo root or vivado/.
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function Find-Vivado {
    if ($env:XILINX_VIVADO) {
        $bat = Join-Path $env:XILINX_VIVADO "bin\vivado.bat"
        if (Test-Path $bat) { return $bat }
    }
    $candidates = @(
        "C:\Xilinx\Vivado\2025.2\bin\vivado.bat",
        "C:\Xilinx\Vivado\2024.2\bin\vivado.bat",
        "C:\AMDDesignTools\Vivado\2025.2\bin\vivado.bat"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

$vivado = Find-Vivado
if (-not $vivado) {
    Write-Error @"
Vivado not found. Install Vivado 2025.2 (matches itch-hw.xpr) or set XILINX_VIVADO.
Then run:
  vivado -mode batch -source vivado/add_sources.tcl
  vivado -mode batch -source vivado/build.tcl
"@
}

Write-Host "Using $vivado"
& $vivado -mode batch -source (Join-Path $repoRoot "vivado\add_sources.tcl")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $vivado -mode batch -source (Join-Path $repoRoot "vivado\build.tcl")
exit $LASTEXITCODE
