<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/9/2017 11:59 AM
	 Modified :     11/15/2017 09:28 AM
     Created by:   	Mark Gladson
	 Organization: 	DXC
	 Filename:     	deployvms.ps1
	===========================================================================
	.DESCRIPTION
		This script can deploy multiple VMs from a .CSV file.  Please see
        the sample newvms.csv file for the format.
#>

$vms = Import-CSV "c:\Scripts\deploy\NewVMs.csv"

#uncomment based on if you are in an Active Directory domain or not

#$name = get-aduser -identity $env:username -Properties name | Select-Object -ExpandProperty name
$name = $env:username



foreach ($vm in $vms)
{
	#Assign Variables
	$VMName = $vm.Name
	$Template = Get-Template -name $vm.Template 
	$Cluster = $vm.Cluster
	$Datastore = Get-Datastore -Name $vm.Datastore
	$Custom = Get-OSCustomizationSpec -Name $vm.Customization
	$vCPU = $vm.vCPU
	$Memory = $vm.Memory
	$Network = $vm.Network
	$Diskformat = $vm.Diskformat
    $Location = $vm.Location
	
	$ipaddress = $vm.ipaddress
	$mask = $vm.mask
	$gateway = $vm.gateway
	$dns1 = $vm.dns1
	$dns2 = $vm.dns2

    $disk1 = $vm.disk1
    $disk2 = $vm.disk2
	
	#setup nic maping in the custimzation specification
	Get-OSCustomizationSpec $Custom | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddress -SubnetMask $mask -DefaultGateway $gateway -Dns $dns1,$dns2 
	
	
	#Build the VM
	New-VM -Name $VMName -Template $Template -ResourcePool (Get-Cluster $Cluster | Get-ResourcePool) -location $location -StorageFormat $Diskformat -Datastore $Datastore -OSCustomizationSpec $Custom
	Start-Sleep -Seconds 10
	
	#Set the vCPU, memory, and network
	$NewVM = Get-VM -Name $VMName
	$NewVM | Set-VM -MemoryGB $Memory -NumCpu $vCPU -Confirm:$false
    $NewVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $Network -Confirm:$false
	 

    #Add Disk 2 if it exists
       if ($disk2 -ne $null)
        { $NewVM | New-HardDisk -CapacityGB $disk2 -StorageFormat $Diskformat }
        else { }

   
    #Set vm build date 
    $notes = "Built By:   " + $name + "`r`nBuild Date: " + (get-date)
    set-vm -vm $newvm -description $notes -Confirm:$false
    
    #Start the VM to continue the customization process
    $NewVM | Start-VM
	
	
	
}

