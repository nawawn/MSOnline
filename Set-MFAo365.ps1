Function Enable-MFAO365{    
    Param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
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
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
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