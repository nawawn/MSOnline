[CmdletBinding()]
Param(
    [Switch]$Count
)
#Requires -Module MsOnline

$Path      = "C:\temp\BulkMsolSample.csv"
$ReqHeader = @('DisplayName','UserPrincipalName','FirstName','LastName','Password')
$Location  = 'GB'
$oLicense  = 'mycompany:STANDARDWOFFPACK'

$Number  = 0
$Failure = 0
$Success = 0

$IsPathCorrect = (Test-Path -Path $Path -PathType leaf)

Function Test-CsvHeader{
    [OutputType([Bool])]
    Param( [String]$Path )        
    
    $HeaderName = (Import-Csv -Path $Path | Select-Object -First 1).PSObject.Properties.Name  
    If($HeaderName){
        return (($ReqHeader | Where-Object{$HeaderName -contains $_}).count -ge ($ReqHeader.count))
    }
    Else { return $false }
<#
.EXAMPLE
   Test-CsvHeader -Path $Path   
#>   
}

Function Test-UPNFormat{
    [OutputType([Bool])]
    Param( $UPN )
    return ([Bool]($UPN -as [System.Net.Mail.MailAddress]))
<#
.EXAMPLE
   Test-UPNFormat -UPN "mtest@mydomain.com"
#>
}

Function Test-MsolUser{
    [OutputType([Bool])]
    Param( $UPN )

    $AlreadyExist = Get-MsolUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue
    return ($null -ne $AlreadyExist)
<#
.EXAMPLE
   Test-MsolUser -UPN tmsoluser@mycompany.com
#>
}

#region Main()

Write-Verbose "Validating CSV folder path..."
If (!($IsPathCorrect)){
    Write-Warning "The CSV file path is not found!"
    return
}

Write-Verbose "Checking CSV column headers..."
If(!(Test-CsvHeader -Path $Path)){
    Write-Warning "Invalid CSV headers!"
    Write-Warning "The header must include: $($ReqHeader -join ", ")."
    return
}

Write-Verbose "Processing CSV file..."
$CsvFile = Import-Csv -Path $Path

Foreach($row in $CsvFile){
    $Number++
    $UPN         = $($row.UserPrincipalName)
    $DisplayName = $($row.DisplayName)
    $FirstName   = $($row.FirstName)
    $LastName    = $($row.LastName)
    $Password    = $($row.Password)

    Write-Verbose "$Number - Creating the user: $DisplayName $UPN"

    If ([String]::IsNullOrWhiteSpace($UPN)){
        Write-Warning "The UserPrincipalName is required and cannot be empty!"
        $Failure++
        Continue
    }
    If (-Not (Test-UPNFormat -UPN $UPN)){
        Write-Warning "The UserPrincipalName format is invalid - $UPN"
        $Failure++
        Continue
    }
    Write-Verbose "Checking if this user already exists: $UPN"
    If (Test-Msoluser -UPN $UPN){
        Write-Warning "This UserPrincipalName already exists - $UPN"
        $Failure++
        Continue
    }   
    
    #If Display Name is empty then concat firstname and lastname    
    If([String]::IsNullOrWhiteSpace($DisplayName)){
        $DisplayName = ($FirstName + " " + $LastName).Trim()
    }
    
    If([String]::IsNullOrWhiteSpace($DisplayName)){
        Write-Warning "The Displayname is required and cannot be empty!"
        $Failure++
        Continue
    }
        
    #Create a new user
    $NewUser = @{}    
    $NewUser.add('UserPrincipalName',$UPN   )  #Mandatory
    $NewUser.add('DisplayName',$DisplayName )  #Mandatory
    If ($FirstName){ $NewUser.add('FirstName',        $FirstName) }
    If ($LastName) { $NewUser.add('LastName',         $LastName ) }
    If ($Password) { $NewUser.add('Password',         $Password ) }
    If ($Location) { $NewUser.add('UsageLocation',    $Location ) }
    If ($oLicense) { $NewUser.add('LicenseAssignment',$oLicense ) }
        
    New-MsolUser @NewUser -ErrorVariable ErrVar -ErrorAction 'SilentlyContinue'   
    If ($ErrVar){
        Write-Output "$($ErrVar.exception)"
        $Failure++
    }
    Else { $Success++ }
        
} #end Foreach

If ($Count){
    Write-Output "Total Failure count: $Failure"
    Write-Output "Total Success count: $Success"
}
#endregion
