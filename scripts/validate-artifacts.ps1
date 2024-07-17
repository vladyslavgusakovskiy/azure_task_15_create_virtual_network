param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [bool]$DownloadArtifacts=$true
)


# default script values 
$taskName = "task15"

$artifactsConfigPath = "$PWD/artifacts.json"
$resourcesTemplateName = "exported-template.json"
$tempFolderPath = "$PWD/temp"

if ($DownloadArtifacts) { 
    Write-Output "Reading config" 
    $artifactsConfig = Get-Content -Path $artifactsConfigPath | ConvertFrom-Json 

    Write-Output "Checking if temp folder exists"
    if (-not (Test-Path "$tempFolderPath")) { 
        Write-Output "Temp folder does not exist, creating..."
        New-Item -ItemType Directory -Path $tempFolderPath
    }

    Write-Output "Downloading artifacts"

    if (-not $artifactsConfig.resourcesTemplate) { 
        throw "Artifact config value 'resourcesTemplate' is empty! Please make sure that you executed the script 'scripts/generate-artifacts.ps1', and commited your changes"
    } 
    Invoke-WebRequest -Uri $artifactsConfig.resourcesTemplate -OutFile "$tempFolderPath/$resourcesTemplateName" -UseBasicParsing

}

Write-Output "Validating artifacts"
$TemplateFileText = [System.IO.File]::ReadAllText("$tempFolderPath/$resourcesTemplateName")
$TemplateObject = ConvertFrom-Json $TemplateFileText -AsHashtable

$virtualNetwork = ( $TemplateObject.resources | Where-Object -Property type -EQ "Microsoft.Network/virtualNetworks" )
if ($virtualNetwork ) {
    if ($virtualNetwork.name.Count -eq 1) { 
        Write-Output "`u{2705} Checked if virtual network exists - OK."
    }  else { 
        Write-Output `u{1F914}
        throw "More than one virtual network resource was found in the task resource group. Please make sure that your script deploys only 1 virtual network, and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to find virtual network in the task resource group. Please make sure that your script creates a virtual network and try again."
}

$virtualNetworkName = $virtualNetwork.name.Replace("[parameters('virtualNetworks_", "").Replace("_name')]", "")
if ($virtualNetworkName -eq "todoapp") { 
    Write-Output "`u{2705} Checked the virtual network name - OK."
} else { 
    Write-Output `u{1F914}
    throw "Unable to verify the virtual network name. Please make sure that your script creates a virtual network called 'todoapp' and try again."
}

if ($virtualNetwork.properties.addressSpace.addressPrefixes -eq "10.20.30.0/24") { 
    Write-Output "`u{2705} Checked the virtual network address space - OK."
} else { 
    Write-Output `u{1F914}
    throw "Unable to verify the virtual network address space. Please make sure that your script creates a virtual network with address space, described in the task, and try again."
}

$subnets = $virtualNetwork.properties.subnets
if ($subnets) {
    if ($subnets.name.Count -eq 3) { 
        Write-Output "`u{2705} Checked if 3 subnets exist - OK."
    }  else { 
        Write-Output `u{1F914}
        throw "Wrong number of subnets was found in the virtual network. Please make sure that your script deploys 3 subnets, and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to find subnets in the virtual network. Please make sure that your script creates 3 subnets and try again."
}

$requiredSubnets = @("webservers", "database", "management") 
foreach ($requiredSubnet in $requiredSubnets) { 
    $artifactSubnet = $subnets | Where-Object {$_.name -eq $requiredSubnet} 
    if ($artifactSubnet) { 
        if ($artifactSubnet.properties.addressPrefix.EndsWith("/26")) { 
            Write-Output "`u{2705} Checked $requiredSubnet subnet - OK."
        } else {
            Write-Output `u{1F914}
            throw "Unable to verify subnet $requiredSubnet address space. Please make sure that you are creating a subnet, which can fit 50 hosts and uses address space effectively (confider creating /26 subnet)."        
        }
    } else { 
        Write-Output `u{1F914}
        throw "Unable to verify subnet '$requiredSubnet' in the virtual network. Please make sure that your script creates 3 subnets and try again."
    }
}

Write-Output ""
Write-Output "`u{1F973} Congratulations! All tests passed!"
