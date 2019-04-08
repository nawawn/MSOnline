[CmdletBinding()]
Param(
    $Path = "C:\Temp\AllDistList.csv"
)

If (!(Test-Path -Path $Path -PathType leaf)){
    Write-Warning "The CSV file path is not found!"
    return
}

If(!((Get-PSSession).where{($_.computername -eq "outlook.office365.com") -and ($_.ConfigurationName -eq "Microsoft.Exchange")})){
    Write-Warning "Please Connect to Exchange Online PowerShell!"
    return
}

Function Test-EODistributionGroup{
    [OutputType([Bool])]
    Param( $Name )
    $AlreadyExist = Get-DistributionGroup -Identity $Name -ErrorAction SilentlyContinue
    return ($null -ne $AlreadyExist)
<#
.EXAMPLE
   Test-EODistributionGroup -Name "DG-Test"
#> 
}

#region Controller

$AllDG = Import-Csv -Path $Path

Foreach($DG in $AllDG){   
    $Identity = $DG.Name
    $Members  = If($($DG.Members)){$DG.Members -split ","} Else{ $null }
       
    If (!(Test-EODistributionGroup -Name $Identity)){        
        New-DistributionGroup -Name $Identity -Alias $($DG.Alias) -DisplayName $($DG.DisplayName) -Type $($DG.Type) -PrimarySMTPAddress $($DG.PrimarySMTPAddress)
        Write-Verbose "$Identity is created."
        Start-Sleep 3
        If($Members){
            Foreach ($m in $Members){            
                Add-DistributionGroupMember -Identity $Identity -Member $m -Confirm:$false
                Write-Verbose " - $m has been added to $Identity!"
            }
        }
    }
    Else {
        Write-Warning "$Identity already exists!"
        $CurrentMem = (Get-DistributionGroupMember -Identity $Identity).Name
        If(($null -eq $CurrentMem) -and ($Members)){
            Foreach ($m in $Members){            
                Add-DistributionGroupMember -Identity $Identity -Member $m -Confirm:$false
                Write-Verbose " - $m has been added to $Identity!"
            }
        }
    }
}
#endregion Controller
