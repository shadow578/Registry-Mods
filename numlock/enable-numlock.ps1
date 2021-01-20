
#region Globals
$TARGET_KEY = "InitialKeyboardIndicators"
$TARGET_VALUE = 0x2
$TARGET_PATHS_GLOBAL = @(
"HKCR:\Control Panel\Keyboard",
"HKCU:\Control Panel\Keyboard",
"HKCU:\Software\Classes\Control Panel\Keyboard",
"HKU:\.Default\Control Panel\Keyboard")
$TARGET_PATHS_PER_USER = @(
"Control Panel\Keyboard",
"Software\Classes\Control Panel\Keyboard")

$CREATE_NONEXISTING_KEYS = $false
$MOUNT_REGISTRY = $true
#endregion

#region Registry Util
function Set-RegistryItemValue([string] $path, [string] $item, [string] $value)
{
    Set-ItemProperty -Path $path -Name $item -Value $value
}

function Get-RegistryItemValue([string] $path, [string] $item)
{
    Get-ItemPropertyValue -Path $path -Name $item
}

function Test-RegistryItemExists([string] $path, [string] $item)
{
    $null -ne (Get-ItemProperty -Path $path -Name $item -ErrorAction SilentlyContinue)
}

function Update-RegistryItemValue([string] $path, [string] $item, [string] $value)
{
    if (!(Test-RegistryItemExists $path $item) -and !($CREATE_NONEXISTING_KEYS))
    {
        Write-Host "skip updating $path :: $($item): does not exist and CREATE_NONEXISTING_KEYS is $CREATE_NONEXISTING_KEYS"
        return
    }

    if (!(Test-RegistryItemExists $path $item) -or ((Get-RegistryItemValue $path $item) -ne $value))
    {
        Write-Host "update value of $path :: $item to $value"
        Set-RegistryItemValue $path $item $value
    }
    else 
    {
        Write-Host "skip updating $path :: $($item): value already set"
    }
}
#endregion


#mount registry locations HKCU, HKCR, HKLM, HKU
if ($MOUNT_REGISTRY)
{
    Write-Host "mount Registry..."
    New-PSDrive -PSProvider Registry -Name "HKCR" -Root "HKEY_CLASSES_ROOT"
    New-PSDrive -PSProvider Registry -Name "HKLM" -Root "HKEY_LOCAL_MACHINE"
    New-PSDrive -PSProvider Registry -Name "HKCU" -Root "HKEY_CURRENT_USER"
    New-PSDrive -PSProvider Registry -Name "HKU" -Root "HKEY_USERS"
}

#apply global paths
Write-Host "update globals..."
foreach ($global in $TARGET_PATHS_GLOBAL)
{
    Update-RegistryItemValue -path $global -item $TARGET_KEY -value $TARGET_VALUE
}

#apply per-user paths
Write-Host "update per-user..."
foreach ($user in (Get-ChildItem -Path "HKU:\"))
{
    $userHive = [System.IO.Path]::GetFileName($user)
    Write-Host "update user hive: $userHive"
    foreach ($perUser in $TARGET_PATHS_PER_USER)
    {
        Update-RegistryItemValue -path "HKU:\$userHive\$perUser" -item $TARGET_KEY -value $TARGET_VALUE
    }
}

#done
Write-Host "finished updating."