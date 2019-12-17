
#Login-AzureRmAccount


Write-Host "....Azure Script Started....."

$vmSize="Standard_DS1_V2"
$start=1;  #Baslangic kullanici numarasi
$end=3  #Bitis kullanici numarasi
$prefix="zxcwc"
$location="northeurope"
$networksCidr="192.25.0.0/24"
$shutdownTime="19:00"
$adminPassword="qweASD123!!!"
$securePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force


Write-Host "....Azure Network Setup....."


$commonRg=New-AzureRmResourceGroup -Name $prefix-common-rg -Location $location -Force

$vmSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name $prefix-vm-subnet -AddressPrefix $networksCidr

$vnet=New-AzureRmVirtualNetwork -Name $prefix-vnet -ResourceGroupName $prefix-common-rg -Location $location -AddressPrefix $networksCidr -Subnet $vmSubnet -Force

Write-Host "....Azure VM Setup....."

$scriptBlock = {
  param ($rg,$prefix,$i,$location,$securePassword,$vnet,$vmSize,$diagStorageName,$shutdownTime)
  $dep=New-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName `
  -Name $prefix-$i-deployment `
  -TemplateFile https://raw.githubusercontent.com/karabasosman/azure-demos/master/template.json `
  -TemplateParameterFile https://raw.githubusercontent.com/karabasosman/azure-demos/master/parameters.json `
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
  -autoShutdownTime $shutdownTime `
  -publicIpAddressType Dynamic `
  -publicIpAddressSku Basic `
  -osDiskType Premium_LRS `
  -diagnosticsStorageAccountType Standard_LRS `
  -diagnosticsStorageAccountKind Storage `
  -autoShutdownTimeZone UTC `
  -autoShutdownStatus Enabled `
  -autoShutdownNotificationStatus Disabled `
  -autoShutdownNotificationLocale en
}

For ($i=$start; $i -le $end; $i++) {
    


   $rg=New-AzureRmResourceGroup -Name $prefix-user-$i-rg -Location $location -Force

    Write-Host "....Resource group $prefix-user-$i created...."

    $diagStorageName=$prefix+"user"+$i+"diagsa"

    $jobName=$prefix+"user"+$i
  
    Start-Job -ScriptBlock $scriptBlock -ArgumentList @($rg,$prefix,$i,$location,$securePassword,$vnet,$vmSize,$diagStorageName,$shutdownTime)



    $workspaceName=$prefix+"ml"+$i

    $mlDep=New-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName `
                                                -Name $prefix-$i-deployment `
                                                -workspaceName $workspaceName `
                                                  -location $location `
                                               -TemplateFile https://raw.githubusercontent.com/karabasosman/azure-demos/master/azure.ml.json 
                                             
                                                                                      

     Write-Host "....VM $prefix-user-$i created...."
   
}

Write-Host "....Azure Script Completed....."
