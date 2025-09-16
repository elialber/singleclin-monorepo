# PowerShell script for running .NET tests with coverage
param(
    [string]$Configuration = "Release",
    [switch]$Coverage,
    [switch]$Watch,
    [string]$Filter = "",
    [switch]$Parallel,
    [switch]$Verbose,
    [string]$Logger = "",
    [switch]$NoBuild
)

Write-Host "SingleClin API Test Runner" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Set working directory
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ProjectDir

# Create output directories
New-Item -Path "../coverage" -ItemType Directory -Force | Out-Null
New-Item -Path "../TestResults" -ItemType Directory -Force | Out-Null

# Base test command
$TestCommand = "dotnet test"

# Add configuration
$TestCommand += " --configuration $Configuration"

# Add no-build flag
if ($NoBuild) {
    $TestCommand += " --no-build"
}

# Add verbosity
if ($Verbose) {
    $TestCommand += " --verbosity detailed"
} else {
    $TestCommand += " --verbosity normal"
}

# Add filter
if ($Filter) {
    $TestCommand += " --filter `"$Filter`""
}

# Add logger
if ($Logger) {
    $TestCommand += " --logger $Logger"
} else {
    $TestCommand += " --logger trx --logger console"
}

# Add settings file
$TestCommand += " --settings test.runsettings"

# Add coverage collection
if ($Coverage) {
    Write-Host "Enabling code coverage collection..." -ForegroundColor Yellow
    $TestCommand += " --collect:`"XPlat Code Coverage`""
    $TestCommand += " /p:CollectCoverage=true"
    $TestCommand += " `"/p:CoverletOutputFormat=opencover,json,lcov,cobertura`""
    $TestCommand += " /p:CoverletOutput=../coverage/"
    $TestCommand += " `"/p:Exclude=[xunit.*]*,[*.Tests]*,[SingleClin.API.Tests]*`""
    $TestCommand += " `"/p:Include=[SingleClin.API]*`""
    $TestCommand += " `"/p:ThresholdType=line,branch,method`""
    $TestCommand += " `"/p:Threshold=80,70,80`""
}

# Add parallel execution
if ($Parallel) {
    $TestCommand += " -- xUnit.ParallelizeTestCollections=true"
}

# Display command
Write-Host "Executing: $TestCommand" -ForegroundColor Cyan

# Execute based on watch mode
if ($Watch) {
    Write-Host "Starting test watcher..." -ForegroundColor Yellow
    $WatchCommand = $TestCommand.Replace("dotnet test", "dotnet watch test")
    Invoke-Expression $WatchCommand
} else {
    # Run tests
    $StartTime = Get-Date
    Invoke-Expression $TestCommand
    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime

    Write-Host ""
    Write-Host "Test execution completed in $($Duration.TotalSeconds) seconds" -ForegroundColor Green

    # Display coverage information if generated
    if ($Coverage) {
        Write-Host ""
        Write-Host "Coverage Reports Generated:" -ForegroundColor Yellow
        Get-ChildItem "../coverage" -Recurse -Include "*.xml", "*.json", "*.info" | ForEach-Object {
            Write-Host "  - $($_.FullName)" -ForegroundColor Gray
        }

        # Try to display coverage summary
        $CoverageJson = Get-ChildItem "../coverage" -Include "coverage.json" -Recurse | Select-Object -First 1
        if ($CoverageJson) {
            try {
                $Coverage = Get-Content $CoverageJson.FullName | ConvertFrom-Json
                Write-Host ""
                Write-Host "Coverage Summary:" -ForegroundColor Yellow
                Write-Host "  Line Coverage: $($Coverage.summary.lineRate * 100)%" -ForegroundColor White
                Write-Host "  Branch Coverage: $($Coverage.summary.branchRate * 100)%" -ForegroundColor White
            } catch {
                Write-Host "Could not parse coverage summary" -ForegroundColor Red
            }
        }
    }
}

# Display test results location
Write-Host ""
Write-Host "Test Results Location:" -ForegroundColor Yellow
Write-Host "  ../TestResults/" -ForegroundColor Gray

if (Test-Path "../TestResults") {
    Get-ChildItem "../TestResults" -Include "*.trx" -Recurse | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
}