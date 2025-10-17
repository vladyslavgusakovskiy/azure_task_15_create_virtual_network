$location = "uksouth"
$resourceGroupName = "mate-azure-task-15"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating subnets ..."
$webserversSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange
$databaseSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange
$managementSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange
$subnetConfigs = $webserversSubnet, $databaseSubnet, $managementSubnet

$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual Network $virtualNetworkName not found. Creating a new VNet ..."

    New-AzVirtualNetwork -Name $virtualNetworkName `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -AddressPrefix $vnetAddressPrefix `
        -Subnet $subnetConfigs

    Write-Host "Virtual Network $virtualNetworkName created successfully."
} else {
    if ($vnet.AddressSpace.AddressPrefixes -notcontains "10.20.30.0/24") {
        $vnet.AddressSpace.AddressPrefixes += "10.20.30.0/24"
        Set-AzVirtualNetwork -VirtualNetwork $vnet
    } else {
        Write-Host "Virtual Network Address Prefix $vnetAddressPrefix already exists. Verifying subnets ..."
        $existingSubnetNames = $vnet.Subnets | ForEach-Object {$_.Name}

        $added = $false

        if ($existingSubnetNames -notcontains $webSubnetName) {
            Write-Host "Adding missing subnet: $webSubnetName"
            Add-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -VirtualNetwork $vnet | Out-Null
            $added = $true
        } else {
            Write-Host "Subnet $webSubnetName already exists. Skipping."
        }

        if ($existingSubnetNames -notcontains $dbSubnetName) {
            Write-Host "Adding missing subnet: $dbSubnetName"
            Add-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -VirtualNetwork $vnet | Out-Null
            $added = $true
        } else {
            Write-Host "Subnet $dbSubnetName already exists. Skipping."
        }

        if ($existingSubnetNames -notcontains $mngSubnetName) {
            Write-Host "Adding missing subnet: $mngSubnetName"
            Add-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -VirtualNetwork $vnet | Out-Null
            $added = $true
        } else {
            Write-Host "Subnet $mngSubnetName already exists. Skipping."
        }

        if ($added) {
            Set-AzVirtualNetwork -VirtualNetwork $vnet | Out-Null
            Write-Host "Persisted subnet additions to VNet."
        }
    }
}
