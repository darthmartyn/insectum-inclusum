param ([string[]]$rtspath = '', [string[]]$target = '')

$gccargs = "-mlittle-endian -mthumb -mfloat-abi=hard -mcpu=cortex-m7 -mfpu=fpv5-sp-d16 -march=armv7e-m+fpv5"

$objdir = Join-Path $PWD "obj"
$srcdir = Join-Path $PWD "src"

$alifiles = @()
$objfiles = @()

foreach ($obj in Get-ChildItem -Path $objdir\*.* -File -Recurse) { Remove-Item -Force -Path $($obj) }

foreach ($src in Get-ChildItem -Path $srcdir\*.adb -File -Recurse)
{
    $alifile = Join-Path $objdir "$($src.BaseName).ali"
    $objfile = Join-Path $objdir "$($src.BaseName).o"
    $adbfile = Join-Path $srcdir "$($src.BaseName).adb"
    Start-Process "$($target)-gcc" -ArgumentList "-g -c -o $($objfile) $($gccargs) --RTS=$($rtspath) $($adbfile)" -NoNewWindow -Wait

    if (!(Test-Path -Path $($objfile)) -or !(Test-Path -Path $($alifile))) { exit 1 }

    $alifiles = $alifiles + $alifile
    $objfiles = $objfiles + $objfile
}

$bindsrc = "gnatbind.adb"
$bindobj = "gnatbind.o"
$image = "gnatbind.elf"

Set-Location $objdir
Start-Process "$($target)-gnatbind" -ArgumentList "-o $($bindsrc) --RTS=$($rtspath) $($alifiles) " -NoNewWindow -Wait

if (Test-Path -Path $($bindsrc))
{
    Start-Process "$($target)-gcc" -ArgumentList "-g -c -o $($bindobj) $($gccargs) --RTS=$($rtspath) $($bindsrc)" -NoNewWindow -Wait

    if (!(Test-Path -Path $($bindobj))) { exit 1 }

    $objfiles = $objfiles + $bindobj
    $libgnat = Join-Path $($rtspath) "adalib\libgnat.a"
    Write-Host $PSScriptRoot
    $gprfile = Get-ChildItem -Path $PSScriptRoot\*.gpr -File

    if (!(Test-Path -Path $($gprfile))) { exit 1 }

    $linkerscript = "linker.ld"
    $crt0src = "crt0.s"
    $crt0obj = "crt0.o"

    Start-Process startup-gen -ArgumentList "-P $($gprfile) -l $($linkerscript) -s $($crt0src)" -NoNewWindow -Wait

    if (!(Test-Path -Path $($linkerscript)) -or (!(Test-Path -Path $($crt0src)))) { exit 1 }

    Start-Process "$($target)-as" -ArgumentList "-o $($crt0obj) $($gccargs) $($crt0src)" -NoNewWindow -Wait
    $objfiles = $objfiles + $($crt0obj)

    Start-Process "$($target)-ld" -ArgumentList "-o $($image) $($objfiles) $($libgnat) -T $($linkerscript)" -NoNewWindow -Wait
}

Set-Location $PSScriptRoot 