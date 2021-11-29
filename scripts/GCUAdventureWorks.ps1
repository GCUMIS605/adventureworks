#Azure initialization script
# User must sign in using az login
Write-Host "Sign into Azure using your credentials.."
az login

# Now sign in again for PowerShell resource management and select subscription
Write-Host "Now sign in again to allow this script to create resources..."
Connect-AzAccount

$subs = Get-AzSubscription | Select-Object
if($subs.GetType().IsArray -and $subs.length -gt 1){
        Write-Host "Multiple subscriptions detected - please select the one you want to use:"
        for($i = 0; $i -lt $subs.length; $i++)
        {
                Write-Host "[$($i)]: $($subs[$i].Name) (ID = $($subs[$i].Id))"
        }
        $selectedIndex = -1
        $selectedValidIndex = 0
        while ($selectedValidIndex -ne 1)
        {
                $enteredValue = Read-Host("Enter 0 to $($subs.Length - 1)")
                if (-not ([string]::IsNullOrEmpty($enteredValue)))
                {
                    if ([int]$enteredValue -in (0..$($subs.Length - 1)))
                    {
                        $selectedIndex = [int]$enteredValue
                        $selectedValidIndex = 1
                    }
                    else
                    {
                        Write-Output "Please enter a valid subscription number."
                    }
                }
                else
                {
                    Write-Output "Please enter a valid subscription number."
                }
        }
        $selectedSub = $subs[$selectedIndex].Id
        Select-AzSubscription -SubscriptionId $selectedSub
        az account set --subscription $selectedSub
}

$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
write-host "User Name: $userName"
$userId = az ad signed-in-user show --query objectId -o tsv
Write-Host "User ID: $userId"

# Register resource providers
Write-Host "Registering resource providers...";
Register-AzResourceProvider -ProviderNamespace Microsoft.Sql
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.Compute

# The sample database name
$databaseName = "AdventureWorks"


# Set an admin login and password for your server
$adminSqlLogin = "SqlAdmin"

# Prompt user for a password for the SQL Database
write-host ""
$sqlPassword = ""
$complexPassword = 0

while ($complexPassword -ne 1)
{
    $sqlPassword = Read-Host "Enter a password for the Azure SQL Database.
    `The password must meet complexity requirements:
    ` - Minimum 8 characters. 
    ` - At least one upper case English letter [A-Z
    ` - At least one lower case English letter [a-z]
    ` - At least one digit [0-9]
    ` - At least one special character (!,@,#,%,^,&,$)
    ` "

    if(($sqlPassword -cmatch '[a-z]') -and ($sqlPassword -cmatch '[A-Z]') -and ($sqlPassword -match '\d') -and ($sqlPassword.length -ge 8) -and ($sqlPassword -match '!|@|#|%|^|&|$'))
    {
        $complexPassword = 1
    }
    else
    {
        Write-Output "$sqlPassword does not meet the compexity requirements."
    }
}


# Generate a random suffix for unique Azure resource names
[string]$suffix =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
Write-Host "Your randomly-generated suffix for Azure resources is $suffix"
$resourceGroupName = "adventureworks-$suffix"
#$location = Read-Host "Enter a region for deployment...centralus,eastus2,southcentralus,westus,westus2"

$preferred_list = "centralus", "eastus", "southcentralus", "westus","westus2"

# Try to create a SQL Databasde resource
$success = 0
$l = 0

$clientIp = Invoke-WebRequest 'https://api.ipify.org' | Select-Object -ExpandProperty Content


while (($success -ne 1) -and ($null -ne $preferred_list[$l])){
    try {
        $success = 1
        $location = $preferred_list[$l]
        $serverName = "server-$(Get-Random)"

        New-AzResourceGroup -Name $resourceGroupName -Location $location -Force | Out-Null

        New-AzSqlServer -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -Location $location `
        -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $sqlPassword -AsPlainText -Force))
        
        New-AzSqlServerFirewallRule 
        -ResourceGroupName $resourceGroupName
        -ServerName $serverName
        -AllowAllAzureIPs
        -FirewallRuleName "adventureworksfwrule"
        -StartIpAddress $clientIp
        -EndIpAddress $clientIp

    }
    catch {
      Remove-AzResourceGroup -Name $resourceGroupName -Force
      $success = 0
      $l = $l+1      
    }
}


# The storage account name and storage container name
$storageAccountName = "sqlimport$(Get-Random)"
$storageContainerName = "importcontainer$(Get-Random)"

# BACPAC file name
$bacpacFilename = "adventureworks.bacpac"



# Create a storage account 
New-AzStorageAccount -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -Location $location `
    -SkuName "Standard_LRS"

# Create a storage container 
New-AzStorageContainer -Name $storageContainerName `
    -Context $(New-AzStorageContext -StorageAccountName $storageAccountName `
        -StorageAccountKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0])

# Download sample database from Github
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #required by Github
Invoke-WebRequest -Uri "https://github.com/GCUMIS605/adventureworks/raw/main/downloads/AdventureWorks.bacpac" -OutFile $bacpacfilename

# Upload sample database into storage container
Set-AzStorageBlobContent -Container $storagecontainername `
    -File $bacpacFilename `
    -Context $(New-AzStorageContext -StorageAccountName $storageAccountName `
        -StorageAccountKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0])


# Import bacpac to database with an S3 performance level
$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -DatabaseMaxSizeBytes 100GB `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0] `
    -StorageUri "https://$storageaccountname.blob.core.windows.net/$storageContainerName/$bacpacFilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S7" `
    -AdministratorLogin "$adminSqlLogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $sqlPassword -AsPlainText -Force)

# Check import status and wait for the import to complete
$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
[Console]::Write("Importing")
while ($importStatus.Status -eq "InProgress")
{
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write(".")
    Start-Sleep -s 10
}
[Console]::WriteLine("")
$importStatus

# Scale down to S0 after import is complete
Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName  `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0"

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
