# SCCM

SCCM module

### Resources

- **Clear-SCCMClientCache**  
  - Clears the SCCM Client Cache

- **Get-CMDeviceCollectionMember** 
  - Retieves the Members in an SCCM Device Collection.  
  
- **Get-SCMSoftwareUpdate**  
  - Gets SCCM Software Update Informatlion.  This is actually different from the built in Get-CMSoftwareUpdate.  The data retrieved is different.  
  
- **Get-SCCMSoftwareUpdateMemberof**  

- **Remove-SCCMSoftwareUpdateFromGroup**
  - Removes a software update from an SCCM Software update group.  You can use this to remove superseded or expired updates.
  
  - **`[PSObject[]]`SoftwareUpdate** (_Mandatory_):  Software update object that you want to remove.  Use Get-CMSoftwareUpdate to get this object.
  - **`[String]`SoftwareUpdateGroupName** (_Optional_): Software update group you are removing the update from.  If this is left blank then the update will be removed from all Software Update Groups.

- **Set-CMBaselineFromSUG**  
  - Assigns Updates from a Software Updtate Group to a Configuration Baseline
  
- **Start-CMClientAction**  
  - Initiates an SCCM action on the remote client

-   
  
### To install

Download the SCCM.psd1 and SCCM.psm1 files and place them where you keep your powershell modules.  usually this is in the c:\program files\windows powershell\module directory.  They need to be a folder named the same as the module.  In this case SCCM.

