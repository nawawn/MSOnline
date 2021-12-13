Function Enable-MFAO365{    
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$UserPrincipalName
    )
    Begin{
        $MFA = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement        
        $MFA.State        = "Enabled"
        $MFA.RelyingParty = "*"
        $MFA.RememberDevicesNotIssuedBefore = (Get-Date)
    }
    Process{
        $MFAState = (Get-MsolUser -UserPrincipalName $UserPrincipalName).StrongAuthenticationRequirements
        If ($MFAState){
            Write-Output "$UserPrincipalName - MFA already $($MFAState.State)"
        }
        Else {
            Write-Verbose "$UserPrincipalName - MFA is getting enabled"
            Set-MsolUser -UserPrincipalName $UserPrincipalName -StrongAuthenticationRequirements $MFA
        } 
    }
<#
.EXAMPLE
   Enable-MFAO365 -UserPrincipalName <UserPrincipalName>
.EXAMPLE
   Get-MsolUser -UserPrincipalName <UserPrincipalName> | Enable-MFAO365
#>
}

Function Disable-MFAO365{    
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$UserPrincipalName
    )
    Begin{
        $MFA = @()
    }
    Process{
        $MFAState = (Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction SilentlyContinue).StrongAuthenticationRequirements
        If ($MFAState){
            Write-Verbose "$UserPrincipalName - MFA is getting disabled"
            Set-MsolUser -UserPrincipalName $UserPrincipalName -StrongAuthenticationRequirements $MFA
            
        }
        Else {
            Write-Output "$UserPrincipalName - MFA is already disabled"
        } 
    }
<#
.EXAMPLE
   Disable-MFAO365 -UserPrincipalName <UserPrincipalName>
.EXAMPLE
   Get-MsolUser -UserPrincipalName <UserPrincipalName> | Disable-MFAO365
#>
}

Function Test-MFAO365{    
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$UserPrincipalName,
        [Switch]$Quiet
    )
    Process{
        $MFAState = (Get-MsolUser -UserPrincipalName $UserPrincipalName).StrongAuthenticationRequirements        
        If ($Quiet){
            ($($MFAState.State) -eq 'Enabled') -or ($($MFAState.State) -eq 'Enforced')
        }
        Else{            
            [PSCustomObject][Ordered]@{
                UserPrincipalName = $UserPrincipalName
                MFAStatus         = $($MFAState.State)
            }
        }               
    }
<#
.EXAMPLE
   Test-MFAO365 -UserPrincipalName <UserPrincipalName>
.EXAMPLE
   Test-MFAO365 -UserPrincipalName <UserPrincipalName> -Quiet
.EXAMPLE
   Get-MsolUser -UserPrincipalName <UserPrincipalName> | Test-MFAO365
#>
}
