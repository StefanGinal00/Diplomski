param(
    [string]$Godot = 'C:\Users\Stefan\Desktop\Godot_v4.6.2-stable_win64.exe',
    [string]$Filter = '*_smoke.gd',
    [int]$TimeoutSeconds = 90
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$runFolder = Join-Path $projectRoot ('.tmp-smoke-suite-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$null = New-Item -ItemType Directory -Path $runFolder
$testFiles = @(Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter $Filter | Sort-Object Name)
if (-not $testFiles.Count) { throw 'No smoke tests matched.' }
# Refuse tests whose save isolation has not been made explicit. Preview scripts
# and helper libraries are deliberately not included in the smoke-test glob.
foreach ($testFile in $testFiles) {
    $source = Get-Content -Raw -LiteralPath $testFile.FullName
    if ($source -notmatch 'save_path\s*=\s*"res://_tmp_[^"]+\.json"') {
        throw ('No isolated temporary save declared: ' + $testFile.Name)
    }
}
$results = @()
$process = $null
Write-Output ("RUN_FOLDER " + $runFolder)
try {
    foreach ($testFile in $testFiles) {
        $testName = $testFile.BaseName
        $logPath = Join-Path $runFolder ($testName + '.log')
        $stdoutPath = Join-Path $runFolder ($testName + '.stdout')
        $stderrPath = Join-Path $runFolder ($testName + '.stderr')
        $arguments = @('--headless', '--path', ('"' + $projectRoot + '"'),
            '--log-file', ('"' + $logPath + '"'), '--fixed-fps', '60',
            '--script', ('res://tests/' + $testFile.Name), '--quit-after', '150000')
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -WorkingDirectory $projectRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $null = $process.Handle
        $timedOut = $false
        $scriptError = $false
        while (-not $process.WaitForExit(500)) {
            if (Test-Path -LiteralPath $logPath) {
                $partial = Get-Content -Raw -LiteralPath $logPath
                # Unhandled script exceptions frequently leave SceneTree running.
                if ($partial -match 'SCRIPT ERROR:') { $scriptError = $true; break }
            }
            if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds) { $timedOut = $true; break }
        }
        if (-not $process.HasExited) {
            # Only the exact child process started for this test is terminated.
            $process.Kill()
            $process.WaitForExit()
        }
        $timer.Stop()
        $output = if (Test-Path -LiteralPath $logPath) { Get-Content -Raw -LiteralPath $logPath } else { '' }
        $errors = @($output -split "\r?\n" | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:)' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.$' })
        $passedMarker = $output -match 'TEST PASSED'
        $status = if ($timedOut) { 'TIMEOUT' } elseif ($scriptError -or $errors.Count -gt 0 -or -not $passedMarker -or $process.ExitCode -ne 0) { 'FAIL' } else { 'PASS' }
        $results += [PSCustomObject]@{
            Test = $testFile.Name
            Status = $status
            Seconds = [math]::Round($timer.Elapsed.TotalSeconds, 2)
            ExitCode = $process.ExitCode
            PassedMarker = $passedMarker
            Errors = $errors
            Log = $logPath
        }
        Write-Output ("{0}/{1} {2} {3} ({4}s)" -f $results.Count, $testFiles.Count, $status, $testFile.Name, [math]::Round($timer.Elapsed.TotalSeconds, 1))
        $process.Dispose()
        $process = $null
        $results | ConvertTo-Json -Depth 5 | Out-File -LiteralPath (Join-Path $runFolder 'results.json') -Encoding utf8
    }
} finally {
    if ($process -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
}
$failed = @($results | Where-Object Status -ne 'PASS')
Write-Output ("SUMMARY {0}/{1} passed; {2} failed. Logs: {3}" -f ($results.Count - $failed.Count), $results.Count, $failed.Count, $runFolder)
if ($failed.Count) { exit 1 }
exit 0
