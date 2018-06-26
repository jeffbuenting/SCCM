# SCCM

SCCM module

### Master

Version: 2.0.1

[![Build status](https://ci.appveyor.com/api/projects/status/pwk40ctp7fbxqbah/branch/master?svg=true)](https://ci.appveyor.com/project/jeffbuenting/sccm/branch/master)


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
  
- **Remove-SCCMSoftwareUpdateFromDeploymentPackage**
  - Removes software updates from an SCCM Software Update Deployment Package.  This needs to be done periodically to clean up the unused updates on the deployment points in SCCM.
  
  - **`[PSObject[]]`SoftwareUpdate** (_Mandatory_): Software update to remove from the Deployment Package.
  - **`[String]`DeploymentPackage**: Deployment Package name.
  - **`[Switch]`Force**:  Forces the removal of the software update from a Software Update Deployment Package. This does not remove membership from a Software Update Group.
  - **`[Switch]`Refresh**: Including this switch will refresh the software update deployment package on the deployment point.  For efficiency sake it may be better to do a refresh after all changes have been made.
  
- **Get-SCCMSoftwareUpdateDeploymentPackageUpdateSourcePath**
  - Returns the Source path of an update in a Deployment Package.
  
  - **`[PSObject[]]`SoftwareUpdate** (_Mandatory_):  Software update object that you want to remove.  Use Get-CMSoftwareUpdate to get this object.
  - **`[String]`$DeploymentPackageName** (_Mandatory_): Deployment Package name.
  - **`[String]$SiteServer: SCCM Site Server.  Defaults to the local computer
  
- **Add-SCCMUpdateToDeploymentPackage**  
  - Adds a Software Update to a Software Update Deployment Package in SCCM.
  
  - **`[PSObject[]]`SoftwareUpdate** (_Mandatory_):  Software update object that you want to remove.  Use Get-CMSoftwareUpdate to get this object.
  - **`[String]`$DeploymentPackageName** (_Mandatory_): Deployment Package name.
  - **`[String[]]`SrcPath**: Path to the location where the update has been downloaded.  This should be the parent.  That way if there are multilple GUID Downloads associated with one patch, they will all be included with the update  
  
        This cannot be the same path as another Deployment Package.
  - **`[String]$SiteServer: SCCM Site Server.  Defaults to the local computer
  - **`[Switch]`Refresh**: Including this switch will refresh the software update deployment package on the deployment point.  For efficiency sake it may be better to do a refresh after all changes have been made.
  
- **Refresh-SCCMSoftwareUpdateDeploymentPackage**
  - Refreshes the Software Update Deployment Package on the distribution point.  This Function was moved outside of the other Deployment Package functions because it speeds up the processes to not refresh during pipline input.  
  
  - **`[String]`$DeploymentPackageName** (_Mandatory_): Deployment Package name.
  - **`[String]$SiteServer: SCCM Site Server.  Defaults to the local computer
  
- **Set-CMBaselineFromSUG**  
  - Assigns Updates from a Software Updtate Group to a Configuration Baseline
  
- **Start-CMClientAction**  
  - Initiates an SCCM action on the remote client

-   
  
### To install

Download the SCCM.psd1 and SCCM.psm1 files and place them where you keep your powershell modules.  usually this is in the c:\program files\windows powershell\module directory.  They need to be a folder named the same as the module.  In this case SCCM.

