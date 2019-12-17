
#Login-AzureRmAccount


Write-Host "....Azure Script Started....."

$vmSize="Standard_F2S_V2"
$start=1;  #Baslangic kullanici numarasi
$end=5  #Bitis kullanici numarasi
$prefix="aiacademy"
$location="westeurope"
$networksCidr="192.5.0.0/24"
$shutdownTime="19:00"
$adminPassword="qweASD123!!!"
$securePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force


Write-Host "....Azure Network Setup....."


$commonRg=New-AzureRmResourceGroup -Name $prefix-common-rg -Location $location

$vmSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name $prefix-vm-subnet -AddressPrefix $networksCidr 

$vnet=New-AzureRmVirtualNetwork -Name $prefix-vnet -ResourceGroupName $prefix-common-rg -Location $location -AddressPrefix $networksCidr -Subnet $vmSubnet

Write-Host "....Azure VM Setup....."

For ($i=$start; $i -le $end; $i++) {
    
   $rg=New-AzureRmResourceGroup -Name $prefix-user-$i-rg -Location $location 

    Write-Host "....Resource group $prefix-user-$i created...."

    $diagStorageName=$prefix+"user"+$i+"diagsa"


    $dep=New-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName `
                                             -Name $prefix-$i-deployment `
                                             -TemplateFile .\template.json `
                                             -TemplateParameterFile .\parameters.json `
                                             -location $location `
                                             -adminPassword $securePassword `
                                             -adminUsername $prefix `
                                             -virtualNetworkId $vnet.Id `
                                             -subnetName $prefix-vm-subnet `
                                             -networkInterfaceName $prefix-vm-$i-nic `
                                             -networkSecurityGroupName $prefix-vm-$i-nsg `
                                             -publicIpAddressName $prefix-$i-pip `
                                             -virtualMachineName $prefix-vm-$i `
                                             -virtualMachineSize $vmSize `
                                             -diagnosticsStorageAccountName $diagStorageName  `
                                             -autoShutdownTime $shutdownTime
    $workspaceName=$prefix+"ml"+$i

     $mlDep=New-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName `
                                               -Name $prefix-$i-deployment `
                                               -workspaceName $workspaceName `
                                                 -location $location `
                                               -TemplateFile .\azure.ml.json                                   

     Write-Host "....VM $prefix-user-$i created...."
   
}

Write-Host "....Azure Script Completed....."
