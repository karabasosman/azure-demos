Write-Host "....Azure Script Started....."

$vmSize="Standard_DS1_V2"
$start=56;  #Baslangic kullanici numarasi
$end=57; #Bitis kullanici numarasi
$prefix="doxts"
$location="westeurope"
$networkResourceGroupName=$prefix+"network-rg"
$networksCidr="172.0.0.0/16"
$vmSubnetCidr="172.0.0.0/24"
$bastionSubnetCidr="172.0.1.0/24"
$bastionHostname=$prefix+"-bastion"
$shutdownTime="19:00"
$adminPassword="qweASD123!!!"
$securePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force

Write-Host "....Azure Network Setup....."

$commonRg=New-AzureRmResourceGroup -Name $networkResourceGroupName -Location $location -Force

$vmSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name 'default' -AddressPrefix $vmSubnetCidr


$vnet=New-AzureRmVirtualNetwork -Name $prefix-vnet -ResourceGroupName $networkResourceGroupName -Location $location -AddressPrefix $networksCidr -Subnet $vmSubnet -Force

Write-Host "....Azure Bastion Setup....."

$dep=New-AzureRmResourceGroupDeployment -ResourceGroupName $commonRg.ResourceGroupName `
    -Name $prefix-bastion-deployment `
    -TemplateFile https://raw.githubusercontent.com/karabasosman/azure-demos/dotnet-academy/bastion.json `
    -location $location `
    -bastion-host-name $bastionHostname `
    -bastion-subnet-ip-prefix $bastionSubnetCidr `
    -vnet-name $prefix-vnet

Write-Host "....Azure VM Setup....."

$scriptBlock = {
    param ($rg,$prefix,$i,$location,$securePassword,$vnet,$vmSize,$diagStorageName,$shutdownTime)

    $dep=New-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName `
    -Name $prefix-$i-deployment `
    -TemplateFile https://raw.githubusercontent.com/karabasosman/azure-demos/dotnet-academy/template.json `
    -location $location `
    -vm_size $vmSize `
    -website_name $prefix-$i-app `
    -sql_server_name $prefix-$i-sql-srv `
    -vm_name $prefix-$i `
    -serverfarms_name $prefix-$i-asp `
    -diag_str_name $diagStorageName `
    -nic_name $prefix-$i-nic `
    -vnet_id $vnet.Id `
    -ip_name $prefix-$i-pip `
    -nsg_name $prefix-$i-nsg `
    -shutdown_time $shutdownTime `
    -admin_password $securePassword `
    -admin_username $prefix-adm
}

For ($i=$start; $i -le $end; $i++) {

    $rg=New-AzureRmResourceGroup -Name $prefix-user-$i-rg -Location $location -Force

    Write-Host "....Resource group $prefix-user-$i created...."

    $diagStorageName=$prefix+"user"+$i+"diagsa"

    $job=Start-Job -ScriptBlock $scriptBlock -ArgumentList @($rg,$prefix,$i,$location,$securePassword,$vnet,$vmSize,$diagStorageName,$shutdownTime)

    $job.Id

    Write-Host "....Job $job.Id created...."
    Write-Host "Note : If you want to check job status , use command Get-Job -Id  "
}    

Write-Host "....Azure Script Completed....."
