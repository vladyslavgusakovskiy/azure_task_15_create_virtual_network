$location = "uksouth"
$resourceGroupName = "mate-azure-task-15"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "???" # <- calculate subnet ip address range 
$dbSubnetName = "database"
$dbSubnetIpRange = "???" # <- calculate subnet ip address range 
$mngSubnetName = "management"
$mngSubnetIpRange = "???" # <- calculate subnet ip address range 

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a virtual network ..."
# write your code here -> 
