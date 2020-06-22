param ([Parameter(Mandatory)][string]$file, [Parameter(Mandatory)][string]$password, [Parameter(Mandatory)][string]$command, 
        [Parameter()][string]$StartAt = '0', [switch]$usesys, [switch]$showerror)

function Invoke-EscapeString([string]$str){
    $str = $str -replace "`"", "`"`""
    return $str
}

function Invoke-OnHost(){
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$targethost,

        [Parameter(Mandatory)]
        [ValidateSet('cmd', 'powershell')]
        [string]$app,
    
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$cmd,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$pswd,

        [Parameter()]
        [string]$userID = 'Administrator',

        [Parameter()]
        [switch]$displayError,

        [Parameter()]
        [switch]$useSystem
    )
    
    Write-Host "-- Output: $targetHost --" -ForegroundColor Yellow

    ## Collect the output and error output
    $errorOutput = [IO.Path]::GetTempFileName()
    $cmd = Invoke-EscapeString -str $cmd

    if ($useSystem){
        $output = psexec /acceptEula "\\$targethost" -s -u $userID -p $pswd $app /c $cmd 2>$errorOutput
    }
    elseif (-not $useSystem){
        $output = psexec /acceptEula "\\$targethost" -h -u $userID -p $pswd $app /c $cmd 2>$errorOutput
    }
    

    ## Check for any errors
    $errorContent = Get-Content $errorOutput
    Remove-Item $errorOutput

    ## Output and Error
    
    foreach ($line in $output){
        Write-Host $line -ForegroundColor Cyan
    }

    if ($displayError){
        foreach ($line in $errorContent){
            Write-Host $line -ForegroundColor Red
        }
    }

    Write-Host "`n-- End Output: $targetHost --" -ForegroundColor Yellow
}

function Invoke-CommandOnHosts(){
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$hosts,

        [Parameter(Mandatory)]
        [ValidateSet('cmd', 'powershell')]
        [string]$app,
    
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$cmd,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$pswd,

        [Parameter()]
        [string]$UserID = 'Administrator',

        [switch]$DisplayError,

        [Parameter()]
        [switch]$UseSystem,

        [Parameter()]
        [string]$WaitUntil = '0'
    )

    if ($WaitUntil -ne '0'){
        Wait-Until -Time $WaitUntil
    }

    foreach ($hos in (Get-Content $hosts)){
        Invoke-OnHost -targethost $hos -cmd $cmd -pswd $pswd -app $app -displayError:$DisplayError -useSystem:$UseSystem
    }
}

function Wait-Until([string]$Time){
    try{
        (New-TimeSpan -End $Time).TotalSeconds | Sleep
    } catch {
        
    }

}

Invoke-CommandOnHosts -hosts $file -app cmd -cmd $command -pswd $password -UseSystem:$usesys -DisplayError:$showerror -WaitUntil $StartAt