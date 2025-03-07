param ([string[]]$rtspath = '', [string[]]$gcc = '')

$objdir = Join-Path $PWD "obj"
$srcdir = Join-Path $PWD "src"

$alifiles = @()
$objfiles = @()

foreach ($src in Get-ChildItem -Path $srcdir -Include *.adb -File -Recurse)
{
    $alifile = Join-Path $objdir "$($src.BaseName).ali"
    $objfile = Join-Path $objdir "$($src.BaseName).o"
    $adbfile = Join-Path $srcdir "$($src.BaseName).adb"
    Start-Process $($gcc) -ArgumentList "-g -c -o $($objfile) --RTS=$($rtspath) $($adbfile)" -NoNewWindow -Wait

    if (!(Test-Path -Path $($objfile)) -or !(Test-Path -Path $($alifile)))
    {
        Write-Host "Build failed"
        break
    }

    $alifiles = $alifiles + $alifile
    $objfiles = $objfiles + $objfile
}

write-host $alifiles
write-host $objfiles

