[CmdletBinding()]
Param()

$AllDG = Get-DistributionGroup | Sort-Object name

function Resolve-ADCanonicalName{
    [CmdletBinding()]    
    [OutputType([String])]
    Param( 
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        $CanonicalName 
    )    
    Process{
        return ((Get-ADUser -Filter 'Enabled -eq $true' -Properties CanonicalName).Where{$_.CanonicalName -eq $CanonicalName} | 
            Select-Object -ExpandProperty Name )
    }
}

$CsvDG = Foreach($DG in $AllDG){
        Write-Verbose "$DG"
        [PSCustomObject]@{
            Name    = $DG.Name
            Alias   = $DG.Alias        
            Owner   = $DG.Owner        
            Members = ((Get-DistributionGroupMember -Identity $DG.Name).Name) -Join ","
            Type    = If ($DG.RecipientType -eq 'MailUniversalDistributionGroup') {"Distribution"} Else {"Security"}
            ManagedBy   = If ($DG.ManagedBy){ ($DG.ManagedBy | Resolve-ADCanonicalName) -join "," } Else { $null }
            DisplayName = $DG.DisplayName
            PrimarySMTPAddress = $DG.PrimarySMTPAddress
        }
    }

$CsvDG | Export-csv  C:\Temp\AllDistList.csv -NoTypeInformation  
