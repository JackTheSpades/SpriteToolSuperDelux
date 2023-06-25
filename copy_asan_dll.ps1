param (
	[Parameter(Mandatory=$true)][string]$TargetPath,
	[Parameter(Mandatory=$true)][string]$TargetDir,
    [Parameter(Mandatory=$false)][switch]$Info
)

$dlls = dumpbin /DEPENDENTS $TargetPath | findstr asan

function PrintIfVerbose {
    param (
        [Parameter(Mandatory=$true)][string]$message
    )
    if ($Info) {
        Write-Output $message
    }
}

foreach ($dll in $dlls) {
    $dll = $dll.Trim()
    PrintIfVerbose "Trying to copy dependency $dll"
    if (Test-Path $TargetDir\$dll -PathType Leaf) {
        PrintIfVerbose "$dll already exists, removing $TargetDir\$dll"
        Remove-Item -Force $TargetDir\$dll
    }
    $fulldllpath = where.exe $dll
    PrintIfVerbose "Copying $fulldllpath to $TargetDir"
    Copy-Item -Force -Destination $TargetDir -Path $fulldllpath
}