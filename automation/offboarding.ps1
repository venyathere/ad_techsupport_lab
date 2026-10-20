$csv_path = "C:\Users\a-heisenberg\Desktop\offboarding.csv"

$users  = (Import-Csv $csv_path).SamAccountName

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

ForEach ($user in $users) {
    $params = @{
        Identity = $user
        Enabled = $false
    }
    try {
        Set-ADUser @params -ErrorAction Stop

        Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -String (New-RandomPassword) -AsPlainText -Force) -ErrorAction Stop

        Get-ADUser -Identity $user | Move-ADObject -TargetPath "OU=Disabled,OU=Los Pollos Hermanos,DC=lospollos,DC=lab" -ErrorAction Stop


        Get-ADPrincipalGroupMembership $user -ErrorAction Stop |
            Where-Object { $_.SID.Value -notmatch '-513$' } |
            ForEach-Object { Remove-ADGroupMember -Identity $_ -Members $user -Confirm:$false -ErrorAction Stop }
            }
    catch {
        Write-Warning "Failed for $user : $($_.Exception.Message)"
        continue
        }

}