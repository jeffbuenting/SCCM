# ----- New-Maintenace Window to deploy


$MWName = 'CU5 Install'






import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Import-Module sccm -force

set-location :

New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name '5 - Infrastructure A') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/17/2015 10:00 PM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name '6 - Infrastructure B') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/17/2015 11:00 PM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name '7 - Production') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/18/2015 12:00 AM" -DurationCount 1 -DurationInterval Hours )

New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name 'CL-HyperV1') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/17/2015 10:00 PM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name 'CL-HyperV2') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/17/2015 11:00 PM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name 'CL-HyperV3') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/18/2015 12:00 AM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name 'CL-HyperV4') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/18/2015 1:00 AM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name 'CL-HyperV5') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/18/2015 2:00 AM" -DurationCount 1 -DurationInterval Hours )
New-CMMaintenanceWindow -Collection (Get-CMDeviceCollection -Name 'CL-HyperV6') -Name $MWName -Schedule (New-CMSchedule -Nonrecurring -Start "7/18/2015 3:00 AM" -DurationCount 1 -DurationInterval Hours )



