param (
    [string[]]$rtspath = '',
    [string[]]$target = '',
    [string[]]$gccargs = '',
    [string[]]$gpr = '',
    [bool]$startupgen = $true
)

# Setup variables
$objdir = Join-Path $PSScriptRoot "obj"
$srcdir = Join-Path $PSScriptRoot "src"
$libgnat = Join-Path $($rtspath) "adalib\libgnat.a"
$bindsrc = "gnatmain.adb"
$bindobj = "gnatmain.o"
$image = "gnatimage.elf"

# Pre-requisite checks on inputs
if (!(Test-Path -Path $($libgnat)))
{
    Write-Host "RTS is missing libgnat.a";
    exit 1
}

if (!(Test-Path -Path $($gpr)))
{
    Write-Host "Missing GPR file: $($gpr)";
    exit 1
}

$alifiles = @()
$objfiles = @()

foreach ($obj in Get-ChildItem -Path $objdir\*.* -File -Recurse)
{
    Remove-Item -Force -Path $($obj)
}

Start-Sleep 1

foreach ($src in Get-ChildItem -Path $srcdir\*.adb -File -Recurse)
{
    $alifile = Join-Path $objdir "$($src.BaseName).ali"
    $objfile = Join-Path $objdir "$($src.BaseName).o"
    $adbfile = Join-Path $srcdir "$($src.BaseName).adb"
    Start-Process "$($target)-gcc" -ArgumentList "-g -c -o $($objfile) $($gccargs) --RTS=$($rtspath) $($adbfile)" -NoNewWindow -Wait

    if (!(Test-Path -Path $($objfile)) -or !(Test-Path -Path $($alifile)))
    {
        exit 1
    }

    $alifiles = $alifiles + $alifile
    $objfiles = $objfiles + $objfile
}

# It's easier to work within the object directory, so let's move there
Set-Location $objdir
Start-Process "$($target)-gnatbind" -ArgumentList "-o $($bindsrc) --RTS=$($rtspath) $($alifiles) " -NoNewWindow -Wait

if (Test-Path -Path $($bindsrc))
{
    Start-Process "$($target)-gcc" -ArgumentList "-g -c -o $($bindobj) $($gccargs) --RTS=$($rtspath) $($bindsrc)" -NoNewWindow -Wait

    if (!(Test-Path -Path $($bindobj)))
    {
        Write-Host "Compilation of $($bindsrc) FAILED"; exit 1
    }

    $objfiles = $objfiles + $bindobj
    $crt0obj = Join-Path $objdir "crt0.o"

    if ($startupgen)
    {
        $linkerscript = Join-Path $objdir "linker.ld"
        $crt0src = Join-Path $objdir "crt0.s"

        Start-Process startup-gen -ArgumentList "-P $($gpr) -l $($linkerscript) -s $($crt0src)" -NoNewWindow -Wait

        if (!(Test-Path -Path $($linkerscript)))
        {
            Write-Host "Generation of $($linkerscript) FAILED";
            exit 1 
        } else
        {
            if (!(Test-Path -Path $($crt0src)))
            { 
                Write-Host "Generation of $($crt0src) FAILED";
                exit 1 
            }
        }

    } else
    {
        $linkerscript = Join-Path $srcdir "linker.ld"
        if (!(Test-Path -Path $($linkerscript)))
        {
            Write-Host "$($linkerscript) is missing";
            exit 1
        } else
        {
            $crt0src = Join-Path $srcdir "crt0.s"
            if (!(Test-Path -Path $($crt0src)))
            {
                Write-Host "$($crt0src) is missing";
                exit 1
            }        
        }
    }

    Start-Process "$($target)-as" -ArgumentList "-o $($crt0obj) $($gccargs) $($crt0src)" -NoNewWindow -Wait
    $objfiles = $objfiles + $($crt0obj)

    if (!(Test-Path -Path $($crt0obj)))
    {
        Write-Host "Assembly of $($crt0src) FAILED";  exit 1
    }

    Start-Process "$($target)-ld" -ArgumentList "-o $($image) $($objfiles) $($libgnat) -T $($linkerscript)" -NoNewWindow -Wait
}

if (!(Test-Path -Path $($image))) { Write-Host "Linking of $($image) FAILED";  exit 1 }

# A fully built target image is available from here onward...

Set-Location $PSScriptRoot