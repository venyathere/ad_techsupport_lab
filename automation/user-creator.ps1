$csv_path = "C:\Users\a-heisenberg\Desktop\users.csv"
$export_csv_path = "C:\Users\a-heisenberg\Desktop\with_passwords_users.csv"
$base_OU = "Los Pollos Hermanos"
$DC="lospollos"
$DC_tld="lab"
$WhatIf=$true

$ADUsers=(Import-CSV -path $csv_path)
$results = @()

function New-RandomPassword {
    $upper   = 65..90   | ForEach-Object { [char]$_ }
    $lower   = 97..122  | ForEach-Object { [char]$_ }
    $digits  = 48..57   | ForEach-Object { [char]$_ }
    $special = '!','@','#','$','%','&','*','?'

    $chars  = @(
        $upper   | Get-Random
        $lower   | Get-Random
        $digits  | Get-Random
        $special | Get-Random
    )
    $all = $upper + $lower + $digits + $special
    $chars += 1..12 | ForEach-Object { $all | Get-Random }

    -join ($chars | Sort-Object { Get-Random })
}


ForEach ($ADUser in $ADUsers) {
    $base = $(($ADUser.FirstName)[0] + "." + $ADUser.LastName).ToLower()
    $username = $base
    $i = 1

    while (Get-ADUser -Filter "SamAccountName -eq '$username'") {
        $username = "$base$i"
        $i++
    }

    $password = New-RandomPassword

    $user_params = @{
        Name                  = "$($ADUser.FirstName) $($ADUser.LastName) ($username)"
        GivenName             = $ADUser.FirstName
        Surname               = $ADUser.LastName
        SamAccountName        = $username
        Title                 = $ADUser.Title
        Path                  = "OU=$($ADUser.Department), OU=Users, OU=$base_OU, DC=$DC, DC=$DC_tld"
        AccountPassword       = ConvertTo-SecureString -String $password -AsPlainText -Force
        ChangePasswordAtLogon = $true
        Enabled               = $true
        Verbose               = $true
        WhatIf                = $WhatIf
                }

             
    $group_params = @{
        Identity              = $("GG_" + $AdUser.Department)
        Members               = $username
        WhatIf                = $WhatIf
                     }

    try {
        New-ADUser @user_params -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed create user $username : $($_.Exception.Message)"
        continue
    }

    try {
        Add-ADGroupMember @group_params -ErrorAction Stop
        }
    catch {
        Write-Warning "Failed to add to group $username : $($_.Exception.Message)"
        continue
          }
}

if (-not $whatIf) {
    $results | Export-Csv $export_csv_path -NoTypeInformation
}