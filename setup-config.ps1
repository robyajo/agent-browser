param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json")
)

$ErrorActionPreference = "Stop"

function Set-ConfigProperty {
    param(
        [System.Management.Automation.PSObject]$Object,
        [string]$Name,
        [object]$Value
    )

    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    }
    else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

# 1. Prefer Python 3 for running scripts
$pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pythonCmd) {
    $pythonCmd = Get-Command py.exe -ErrorAction SilentlyContinue | Select-Object -First 1
}

$vscodeMcpPy = Join-Path $PSScriptRoot "vscode_mcp.py"
$vscodeMcpExe = Join-Path $PSScriptRoot "vscode_mcp.exe"
$zedMcpPy = Join-Path $PSScriptRoot "zed_mcp.py"

if (Test-Path -LiteralPath $ConfigPath) {
    try {
        $configuration = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        $configuration = [pscustomobject]@{ mcpServers = [pscustomobject]@{} }
    }
}
else {
    $configuration = [pscustomobject]@{ mcpServers = [pscustomobject]@{} }
}

if (-not $configuration.PSObject.Properties["mcpServers"]) {
    $configuration | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([pscustomobject]@{})
}

# Remove legacy servers
if ($configuration.mcpServers.PSObject.Properties["roblox"]) {
    $configuration.mcpServers.PSObject.Properties.Remove("roblox")
}
if ($configuration.mcpServers.PSObject.Properties["effectcraft"]) {
    $configuration.mcpServers.PSObject.Properties.Remove("effectcraft")
}
if ($configuration.mcpServers.PSObject.Properties["zed"]) {
    $configuration.mcpServers.PSObject.Properties.Remove("zed")
}

# Configure VS Code
if ($pythonCmd -and (Test-Path -LiteralPath $vscodeMcpPy)) {
    $vscodeServer = [pscustomobject]@{
        command = $pythonCmd.Source
        args = @($vscodeMcpPy)
        env = [pscustomobject]@{}
    }
    Set-ConfigProperty -Object $configuration.mcpServers -Name "vscode" -Value $vscodeServer
    Write-Host "VS Code MCP configured (Python): $vscodeMcpPy"
}
elseif (Test-Path -LiteralPath $vscodeMcpExe) {
    $vscodeServer = [pscustomobject]@{
        command = $vscodeMcpExe
        args = @()
        env = [pscustomobject]@{}
    }
    Set-ConfigProperty -Object $configuration.mcpServers -Name "vscode" -Value $vscodeServer
    Write-Host "VS Code MCP configured (EXE): $vscodeMcpExe"
}

# Configure Zed Editor
if ($pythonCmd -and (Test-Path -LiteralPath $zedMcpPy)) {
    $zedServer = [pscustomobject]@{
        command = $pythonCmd.Source
        args = @($zedMcpPy)
        env = [pscustomobject]@{}
    }
    Set-ConfigProperty -Object $configuration.mcpServers -Name "zededitor" -Value $zedServer
    Write-Host "Zed MCP configured (Python): $zedMcpPy"
}

$json = ConvertTo-Json -InputObject $configuration -Depth 20
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ConfigPath, "$json`n", $utf8WithoutBom)
Write-Host "MCP configuration saved to $ConfigPath."
