Function Create-ArmTemplate {

    [CmdletBinding()]
    Param([Parameter(Mandatory)][int]$Environment,
    [Parameter(Mandatory)][string]$stfServerShortName,
    [Parameter(Mandatory)][Object[]]$Features,
    [Parameter(Mandatory)][String]$OutputPath)

    Begin {

        $ServerList = @()
        $ServerList += [pscustomobject]@{"Server" = "$stfServerShortName-NL2";"VirtualMachineSize" = "Standard_D8s_v3";"Role" = "standard"; "WindowsVersion" = "Windows_2016"; "LogicalRoles" = "FO-FOS"}
        
        foreach ($feature in $Features) {
            if ($feature.TerminalCount -eq 1) {
                $ServerList += [pscustomobject]@{"Server" = "$($feature.Feature)"+"TRM-NL2";"VirtualMachineSize" = "Standard_D16s_v3";"Role" = "rds"; "WindowsVersion" = "Windows_2016"; "LogicalRoles" = "FO-UI"}
            } elseif ($feature.TerminalCount -lt 10) {
                1..$($feature.TerminalCount) | Foreach { $ServerList += [pscustomobject]@{"Server" = "$($feature.Feature)"+"TM$_-NL2";"VirtualMachineSize" = "Standard_D16s_v3";"Role" = "rds"; "WindowsVersion" = "Windows_2016"; "LogicalRoles" = "FO-UI"} }
            } elseif ($feature.TerminalCount -lt 100) {
                1..$($feature.TerminalCount) | Foreach { $ServerList += [pscustomobject]@{"Server" = "$($feature.Feature)"+"T$_-NL2";"VirtualMachineSize" = "Standard_D16s_v3";"Role" = "rds"; "WindowsVersion" = "Windows_2016"; "LogicalRoles" = "FO-UI"} }
            } else {    
                Write-Error "The Maximum Terminals per feature is limited to 99." -ErrorAction Stop
                
            }
        }
        
        $ServerList | ft

        if ($Environment -le 100) { $armVersion = 'v1.3' } 
        else { $armVersion = 'v1.5' }

        $jsonCollection = @()
        $errorCount = 0
    }
    Process {
        #### Generating Arm Template
        if ($errorCount -eq 0) {
            Write-Host "Generating Arm template"
            Foreach($Server in $ServerList ) {
                $jsonCollection += "`n"
                $serverConfig = @"
   {
      "apiVersion": "2017-05-10",
      "name": "[concat(parameters('environment'),'$($Server.Server)')]",
      "type": "Microsoft.Resources/deployments",
      "properties": {
        "mode": "Incremental",
        "templateLink": {
          "uri": "[concat('https://apprtemplprod.blob.core.windows.net/templates/master/Platform/VirtualMachines/Standard/$armVersion/DteVM.json', parameters('approvedTemplatesToken'))]"
        },
        "parameters": {
          "virtualMachineName": {
            "value": "[concat(parameters('environment'),'$($Server.Server)')]"
          },
          "virtualMachineSize": {
            "value": "$($Server.VirtualMachineSize)"
          },
          "role": {
            "value": "$($Server.Role)"
          },
          "galleryImageDefinitionName": {
            "value": "$($Server.WindowsVersion)"
          },
          "environment": {
            "value": "[parameters('environment')]"
          },
          "primaryLogicalRoles": {
            "value": "$($Server.LogicalRoles)"
          },
          "secondaryLogicalRoles": {
            "value": "$($Server.LogicalRoles)"
          }
        }
      }
    }
"@
                $jsonCollection += $serverConfig + ",   "
            }

            # Removing last comma
            $jsonCollection[$jsonCollection.Count -1] = $jsonCollection[$jsonCollection.Count -1].Substring(0,$jsonCollection[$jsonCollection.Count - 1].Length - 4)
            
            # Creating the ARM Json template for the server List
            $content = @"
{
  "`$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.1",
  "parameters": {
    "approvedTemplatesToken": {
      "type": "string",
      "metadata": {
        "description": "Sas token for accessing approved templates repository."
      }
    },
    "environment": {
      "type": "string",
      "metadata": {
        "description": "Environment type in the form of tstxx, like tst01, tst12 etc"
      }
    }
  },
  "resources": [$jsonCollection
  ],
  "outputs": {}
}
"@
        }
    }
    End {

        # Creating the template File
        if ($errorCount -eq 0) {
			New-item -Path $OutputPath -Force
            $content | Out-File "$OutputPath" -Force
            Write-Host "Successfully generated arm template json file at path $OutputPath"
        }
    }
}

$features = @([pscustomobject]@{"Feature"= "FO"; "TerminalCount" = 2; "AgentCountPerTerminal" = 10},[pscustomobject]@{"Feature"= "BO"; "TerminalCount" = 1; "AgentCountPerTerminal" = 10})
Create-ArmTemplate -Environment 62 -OutputPath "C:\Users\Hemant Sharma\Desktop\armTemplate.json" -stfServerShortName 'STF' -Features $features