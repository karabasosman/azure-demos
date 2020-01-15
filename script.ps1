Write-Host "....Azure Script Started....."

$vmSize="Standard_DS5_V2"
$start=4;  #Baslangic kullanici numarasi
$end=15  #Bitis kullanici numarasi
$prefix="egm"
$location="westeurope"
$networkResourceGroupName=$prefix+"-network-rg"
$adminPassword="qweASD123456"
$securePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force

Write-Host "....Azure Network Setup....."

$vnet=Get-AzureRmVirtualNetwork -Name $prefix-devops-vnet -ResourceGroupName $networkResourceGroupName

Write-Host "....Azure VM Setup....."

$scriptBlock = {
    param ($rg,$prefix,$i,$location,$securePassword,$vnet,$vmSize,$diagStorageName)

    $dep=New-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName `
    -Name $prefix-$i-deployment `
    -TemplateFile https://raw.githubusercontent.com/karabasosman/azure-demos/dotnet-academy-v2/template.json `
    -location $location `
    -subnetName "default" `
    -virtualMachineName $prefix-dev-$i `
    -diagnosticsStorageAccountName $diagStorageName `
    -networkInterfaceName $prefix-$i-nic `
    -virtualNetworkId $vnet.Id `
    -zone "1" `
    -networkSecurityGroupName $prefix-$i-nsg `
    -adminPassword $securePassword `
    -adminUsername "egmdev" `
    -osDiskType "Premium_LRS" `
    -diagnosticsStorageAccountType "Standard_LRS" `
    -diagnosticsStorageAccountKind "Storage" `
    -virtualMachineSize $vmSize
}

For ($i=$start; $i -le $end; $i++) {

    $rg=Get-AzureRmResourceGroup -Name $prefix-user-$i-rg

    Write-Host "....Resource group $prefix-user-$i created...."

    $diagStorageName=$prefix+"user"+$i+"diagsa"

    $job=Start-Job -ScriptBlock $scriptBlock -ArgumentList @($rg,$prefix,$i,$location,$securePassword,$vnet,$vmSize,$diagStorageName)

    Write-Host "....Job $job.Id created...."
    Write-Host "Note : If you want to check job status , use command Get-Job -Id  "
}    

Write-Host "....Azure Script Completed....."
