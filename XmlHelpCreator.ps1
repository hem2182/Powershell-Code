#This will generate a xml file for the module with sample text. Use Update-ModuleXmlHelp of this module to update the xml help file for individual cmdlets
#Use the Updatable switch to generate the updatable help for the module. you also need to pass the HelpInfoUri which is the path of the 
#iis hosting server for the updatable powershell module files.
#the xml help file will have no help generated for the dynamic parameter.
function New-ModuleXmlHelp {

    [CmdletBinding(DefaultParameterSetName="Default")]
    param([Parameter(ParameterSetName="Default")][string]$ModuleName,
    [Parameter(ParameterSetName="UpdatableHelp")][switch]$Updatable,
    [Parameter(ParameterSetName="UpdatableHelp")][string]$HelpInfoUri = "http://sandbox0200.sys.dom/PSHelp")

    Begin {
        #Initial Logic - Import Module and load it in memory
        Import-Module -Name $ModuleName
        $module = Get-Module -Name $ModuleName
        if ($module) {
            $moduleBase = $module.ModuleBase
            $moduleType = $module.ModuleType
            $moduleScript = $module.ExportedFunctions
            $moduleAccessMode = $module.AccessMode

            if ($moduleType -eq "Script") { Write-Warning "Module needs to be of the type Manifest instead of Script." }
        }
        else {
            Write-Warning "$ModuleName does not exists or is not imported into the powershell session."
        }     
    }
    Process {
        
        #### If Manifest module is found, start creating module xml help locally
        ## The xml file needs to go in a language specific folder with a specific name. See what options you have for the language folder. Create the folder --We are using english
        if (!(Test-Path -Path "$($moduleBase)\en-US")) {
            $languageFolder = New-Item "$($moduleBase)\en-US" -ItemType Directory -Force
            $languageFolder
        }
        if(-not $languageFolder) { $languageFolder = "$($moduleBase)\en-US" }
        ## Create the xml file in the language folder with name as <ModuleName.psm1-help.xml> with the basic xml
        if (!(Test-Path -Path "$languageFolder\$ModuleName.psm1-help.xml")) {
            New-Item "$languageFolder\$ModuleName.psm1-help.xml" -ItemType File -Force
        }

        ## Getting all the function details from the module
        $exportedFunctions = $module.ExportedFunctions.Values | Select *

        ## Creating basic XML file structure with root node
        $filePath = "$languageFolder\$ModuleName.psm1-help.xml" 
        $xmlWriter = New-Object System.XMl.XmlTextWriter($filePath,$Null)
        $xmlWriter.Formatting = "Indented"   
        $XmlWriter.IndentChar = "`t" 
        $xmlWriter.WriteStartDocument() 		                #Write the XML decaration
        $xmlWriter.WriteStartElement("helpItems")               #Root element
        $XmlWriter.WriteAttributeString("schema", "maml")       #Define schema as maml. if not defined, the help does not load and work 
        $XmlWriter.WriteComment("all commands xml goes here")	#Adds comments directly into the xml file.

        ## Filling xml with the cmdlets help command:command nodes via calling the helper functions
        foreach($function in $exportedFunctions) {

            #creating the command:command root element
            $xmlWriter.WriteStartElement("command") 
            $XmlWriter.WriteAttributeString("xmlns:maml", "http://schemas.microsoft.com/maml/2004/10") 
            $XmlWriter.WriteAttributeString("xmlns:command", "http://schemas.microsoft.com/maml/dev/command/2004/10") 
            $XmlWriter.WriteAttributeString("xmlns:dev", "http://schemas.microsoft.com/maml/dev/2004/10")
            $XmlWriter.WriteAttributeString("xmlns:MSHelp", "http://msdn.microsoft.com/mshelp")
            $XmlWriter.WriteAttributeString("name", "$($function.Name)")
            
            #Add-CmdletXMLHelp -XmlWriter $xmlWriter -CmdletFunction $function
              #create the command:details node
                Generate-CmdletDetails -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the maml:description node
                Generate-CmdletDescription -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:parameterSets node
                Generate-CmdletParameterSets -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:parameters node
                Generate-CmdletParameters -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:inputTypes node
                Generate-CmdletInputTypes -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:returnValues node
                Generate-CmdletReturnValues -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:terminatingErrors node
                Generate-CmdletTerminatingErrors -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:nonTerminatingErrors node
                Generate-CmdletNonTerminatingErrors -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the maml:alertSet node
                Generate-CmdletAlertSet -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:examples node
                $examplesObj = [System.Object[]] @()
                #$exampleObject = [System.Object] @{
                #    "ExampleCode" = "This is where the sample code for how to use this cmdlet goes in"
                #    "ExampleDescription" = "this is the description of what the cmdlet does and how the result is achieved."
                #}
                #$examplesObj += $exampleObject
                Generate-CmdletExamples -XmlWriter $xmlWriter -CmdLetFunction $function -ExampleObject $examplesObj
              #create the maml:relatedLinks node
                Generate-CmdletRelatedLinks -XmlWriter $xmlWriter -CmdLetFunction $function
            
            #closing the command root element
            $XmlWriter.WriteEndElement() 
            #Closed the command:command tag
        }

        $xmlWriter.WriteEndElement()                            #Closing the helpItems tag
        $xmlWriter.WriteEndDocument()                           #Closing the xml document
        $xmlWriter.Flush()                                      #Clearing it from memory
        $xmlWriter.Close()                                      #Closing the xml document

        If ($Updatable) {
            if ($HelpInfoUri) {
                Create-ModuleUpdatableHelp -ModuleName $ModuleName -HelpInfoUri $HelpInfoUri
            }
            else {
                Write-Output "The local xml file is generated."
                Write-Warning "Please provide HelpInfoUri parameter. It should be a http path for the PsHelp folder on the web server like iis etc"
            }
        }
    }
    End {
        Write-Verbose "XML file for module $ModuleName is successfully created."
    }
}


#Use this function to update the synopsis,parameter description and adding examples to the help file
#this also helps to add description for the cmdlet and remove the already added description
#the cmdlet has a dynamic parameter that gets the name of the cmdlet based on the module name passed and validates the passed cmdlet name.
#this cmdlet will not work for updatable xml file path.
function Update-ModuleXmlHelp {
    [CmdletBinding(DefaultParameterSetName='Description')]
    param([Parameter(Mandatory)][String]$ModuleName,
    [Parameter()][String]$Synopsis,
    [Parameter(ParameterSetName="Description")][String]$Description,
    [Parameter(ParameterSetName="Description")][Switch]$AddDescription,
    [Parameter(ParameterSetName="RemoveDescription")][Int]$RemoveDescriptionIndex,
    [Parameter(HelpMessage="Pass a hashtable of ParameterName,Description. The description for the parameter will be updated.")][hashtable]$ParameterDescription,
    [Parameter(HelpMessage="Pass a hashtable array of ExampleCode,ExampleDescription. The cmdlet example help will be added/updated.")][System.Object[]]$ExampleHelp,
    [Parameter()][Switch]$UpdatableHelp,
    [Parameter()][String]$HelpInfoUri)
    #Created a CmdletName dynamic parameter that auto suggests the name of the cmdlet available in the Module
    DynamicParam {
        $attributes = new-object System.Management.Automation.ParameterAttribute
        $attributes.Mandatory = $true
        #$attributes.ParameterSetName = '__AllParameterSets'

        $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attributes)

        $arrSet = (Get-Command -Module $ModuleName).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)

        $dynParam1 = new-object -Type System.Management.Automation.RuntimeDefinedParameter("CmdletName", [string], $attributeCollection)
            
        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("CmdletName", $dynParam1)
        
        return $paramDictionary
    }

    Begin {
        #Assigning CmdletName Passed for updating the help for the command
        $CmdletName = $paramDictionary.CmdletName.Value

        #Importing Module to load the module cmdlets in the powershell memory
        Import-Module -Name $ModuleName -ErrorAction Stop

        #validating the specified cmdlet exists in the module
        Get-Command -Module $ModuleName -Name $CmdletName -ErrorAction Stop | Out-Null

        #loading cmdletInfo 
        $cmdletInfo = Get-Command -Module $ModuleName -Name $CmdletName | Select *
    }
    Process {
        #Loading the xml help file for the module
        $module = Get-Module -Name $ModuleName
        [xml]$xml = Get-Content -Path "$($module.ModuleBase)\en-US\$ModuleName.psm1-help.xml"
        #Getting the xml help for the specified cmdlet
        $functionNode = $xml.helpItems.command | Where { $_.details.Name -eq $CmdletName }

        if ($Synopsis) {
            Write-Verbose "Updating Synopsis for Cmdlet $CmdletName..."
            $functionNode.details.description.para = "$Synopsis"
            $Xml.Save("$($module.ModuleBase)\en-US\$ModuleName.psm1-help.xml")
            Write-Verbose "Successfully Updated Synopsis for cmdlet $CmdletName."
        }
        if ($Description) {
            if ($AddDescription) {
                Write-Verbose "Adding description line for Cmdlet $CmdletName..."
                $descriptionPara = $xml.CreateNode("Element","maml","para","")
                $descriptionPara.InnerText = "$Description"
                
                $functionNode.description.AppendChild($descriptionPara)
            }
            else {
                Write-Verbose "Updating Description for Cmdlet $CmdletName..."
                $descriptionParaCount = $functionNode.description.para.Count
                if ($descriptionParaCount -gt 1) {
                    Write-Verbose "Found multiple description para. Updating the first para content..."
                    $functionNode.description.FirstChild.'#text' = "$Description"
                }
                else {
                    $functionNode.description.para = "$Description"
                }
                
            }
            $Xml.Save("$($module.ModuleBase)\en-US\$ModuleName.psm1-help.xml")
            Write-Verbose "Successfully Updated Description for cmdlet $CmdletName."
        }
        if ($RemoveDescriptionIndex) {
            #Getting all the description child nodes
            [System.Xml.XmlNodeList]$descriptionChildNodes = $functionNode.description.ChildNodes

            #validating the passed index number.
            if ($descriptionChildNodes.Count -gt $RemoveDescriptionIndex) {
                #To Remove a node from description
                $functionNode.description.RemoveChild($descriptionChildNodes[$RemoveDescriptionIndex])
                $Xml.Save("$($module.ModuleBase)\en-US\$ModuleName.psm1-help.xml")
                Write-Verbose "Successfully Removed Description for cmdlet $CmdletName at index $RemoveDescriptionIndex."
            }
            else {
                Write-Warning "The description index does not exists."
            }
        }
        if ($ParameterDescription) {
            if ($ParameterDescription.Keys.Count -eq 2 -and $ParameterDescription.Keys -contains "ParameterName" -and $ParameterDescription.Keys -contains "Description") {
                #Validating Parameter Name passed into the hashtable.
                $validParameter = (Get-Command -Module $ModuleName -Name $CmdletName).Parameters.ContainsKey("$($ParameterDescription.ParameterName)")
                if($validParameter) {
                    #update the parameter help description
                    Write-Verbose "Updating Parameter description for Cmdlet $CmdletName parameter $($ParameterDescription.ParameterName)..."
                    $parameterInfo = $functionNode.parameters.parameter | Where { $_.name -eq $($ParameterDescription.ParameterName) } | Select *
                    $desc = $ParameterDescription.Description
                    Write-HOst "Parameter description is: $desc"
                    $parameterInfo.description.para = "$desc"

                    #updating the parameter Set parameter description also before saving the updated content.
                    Write-Verbose "Updating the parameter description of the parameter in Parameter Sets also..."
                    $syntaxInfo = $functionNode.syntax.syntaxItem | Where { $_.parameter.name -eq $($ParameterDescription.ParameterName) }
                    
                    foreach ($syntaxItem in $syntaxInfo) {
                        $item = $syntaxItem.parameter | Where { $_.name -eq $($ParameterDescription.ParameterName) }
                        $item.description.para = "$desc"
                    }
                    Write-Verbose "Successfully updated parameter description in parameters sets"

                    #Save the changes
                    $Xml.Save("$($module.ModuleBase)\en-US\$ModuleName.psm1-help.xml")
                    Write-Verbose "Successfully Updated Parameter and ParameterSets description for parameter $($ParameterDescription.ParameterName) for cmdlet $CmdletName."
                }
                else { Write-Warning "Unable to validate Parameter:$($ParameterDescription.ParameterName). Cannot find $($ParameterDescription.ParameterName) as cmdlet parameter. Make sure the cmdlet name or the parameter name is correct" }

            }
            else {
                Write-Warning "Invalid hashtable for updating parameters. It should contain keys as ParameterName,Description of the parameter that belongs to the cmdlet."
            }
        }
        if ($ExampleHelp) {
            foreach($helpContent in $ExampleHelp) { 
                #Validating Input HashTable
                Write-Verbose "Validating Example Input HashTable..."
                if ($helpContent.Keys.Count -eq 2 -and $helpContent.Keys -contains "ExampleCode" -and $helpContent.Keys -contains "ExampleDescription") {
                    #once the example hashtable is validated, 
                    Write-Verbose "Example Input Hashtable validated successfullly."

                    #validating the ExampleCode --The Code result is not showing in the formatted manner in the xml help file.
                    Write-Verbose "Validating Example Code. It should be executable without any errors..."
                    $exampleCodeResult = Invoke-Expression $helpContent.ExampleCode -ErrorAction Stop
                    Write-Verbose "ExampleCode validation successful"

                    #Add the example to the cmdlet.
                    Write-Verbose "Adding Example for Cmdlet $CmdletName..."

                    #Finding number of examples already added
                    $exampleCount = $functionNode.examples.ChildNodes.Count

                    #creating example node
                    Write-Verbose "Creating new example xml node"
                    if ($exampleCount -eq 0 ) {
                        $example = $xml.CreateElement('command:example')
                    }
                    else {
                        $example = $xml.CreateNode("Element","command","example","")
                        
                    }
                    $title = $xml.CreateNode("Element","maml","title","")
                    $title.InnerText = "--------------------------  Example $($exampleCount + 1)  --------------------------"
                    $introduction = $xml.CreateNode("Element","maml","introduction","")
                    $intropara = $xml.CreateNode("Element","maml","para","")
                    $intropara.InnerText = "PS C:\>"
                    $devcode = $xml.CreateNode("Element","dev","code","")
                    $devcode.InnerText = "$($helpContent.ExampleCode)
                    $exampleCodeResult"
                    $devremarks = $xml.CreateNode("Element","dev","remarks","")
                    $remarkspara = $xml.CreateNode("Element","maml","para","")
                    $remarkspara.InnerText = "$($helpContent.ExampleDescription)"
                    $commandLines = $xml.CreateNode("Element","command","commandLines","")
                    $commandLine = $xml.CreateNode("Element","command","commandLine","")
                    $commadText = $xml.CreateNode("Element","command","commandText","")
                    $commandTextMamlPara = $xml.CreateNode("Element","maml","para","")
                    
                    $introduction.AppendChild($intropara)
                    $devremarks.AppendChild($remarkspara)
                    $commadText.AppendChild($commandTextMamlPara)
                    $commandLine.AppendChild($commadText)
                    $commandLines.AppendChild($commandLine)
                    
                    $example.AppendChild($title)
                    $example.AppendChild($introduction)
                    $example.AppendChild($devcode)
                    $example.AppendChild($devremarks)
                    $example.AppendChild($commandLines)

                    if ($count -eq 0 ) {
                        $xpath = "/helpItems/command[@name=`"$($functionNode.name)`"]/examples"
                        $xpath
                        $xml.SelectSingleNode("/helpItems/command[@name=`"$($functionNode.name)`"]/examples").AppendChild($example)
                    }
                    else {
                        $functionNode.examples.AppendChild($example)
                    }

                    $Xml.Save("$($module.ModuleBase)\en-US\$ModuleName.psm1-help.xml")
                    Write-Verbose "Successfully added cmdlet example help"
                }
                else {
                    Write-Warning "Invalid hashtable array for adding/updating examples. It should contain keys as ExampleCode,ExampleCodeResult,ExampleDescription"
                }
            }    
        }
    }
    End {
    }  
}




#region helper Functions for creating the initial xml file.

#generates synopsis
function Generate-CmdletDetails { 
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction)
    
    Process {
                $xmlWriter.WriteStartElement("command:details")
                $xmlWriter.WriteElementString("command:name","$($CmdLetFunction.Name)")
                $xmlWriter.WriteStartElement("maml:description")
                $xmlWriter.WriteElementString("maml:para","Write a small synopsis of what this cmdlet does. Just an Overview.
                Execute Update-ModuleXmlHelp -ModuleName $($CmdLetFunction.ModuleName) -CmdletName $($CmdLetFunction.Name) -Synopsis SynopsisDescription
                to update the synopsis of the cmdlet.")
                $XmlWriter.WriteEndElement()
                $xmlWriter.WriteStartElement("maml:copyright")
                $xmlWriter.WriteElementString("maml:para","")
                $XmlWriter.WriteEndElement()
                $xmlWriter.WriteElementString("command:verb","$($CmdLetFunction.Verb)")
                $xmlWriter.WriteElementString("command:noun","$($CmdLetFunction.Noun)")
                $xmlWriter.WriteElementString("dev:version","")
                $XmlWriter.WriteEndElement() 
            }
}
#generates Description
function Generate-CmdletDescription {
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        $xmlWriter.WriteStartElement("maml:description")
        $xmlWriter.WriteElementString("maml:para","Add the detailed description of what the cmdlet is about.
        Execute Update-ModuleXmlHelp -ModuleName $($CmdLetFunction.ModuleName) -CmdletName $($CmdLetFunction.Name) -Description DescriptionText
        to update the description.
        Execute Update-ModuleXmlHelp -ModuleName $($CmdLetFunction.ModuleName) -CmdletName $($CmdLetFunction.Name) -Description DescriptionText -Add
        to add another line of description about the cmdlet.")
        $XmlWriter.WriteEndElement()
    }
}
#generates parameter information
function Generate-CmdletParameters {     
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        ##Creating the command:parameters subElement
        $xmlWriter.WriteStartElement("command:parameters")
        $parameters = $CmdLetFunction.Parameters.Values | Where { $_.Attributes -match "ArgumentType" } | Select *
        foreach ($parameter in $parameters) {

            $parameterInfo = (Get-Command $($CmdLetFunction.Name)).Parameters.$($parameter.Name).Attributes

            ##Starting parameter Tag  
            $xmlWriter.WriteStartElement("command:parameter")
            $XmlWriter.WriteAttributeString("required", "$($parameterInfo.Mandatory)") 
            $XmlWriter.WriteAttributeString("variableLength", "false") 
            $XmlWriter.WriteAttributeString("globbing", "false")
            $XmlWriter.WriteAttributeString("pipelineInput", "$($parameterInfo.ValueFromPipeline)")
            if($parameterInfo.Position -eq "-2147483648") { $parameterPosition = "named" } else { $parameterPosition = $parameterInfo.Position }
            $XmlWriter.WriteAttributeString("position", "$parameterPosition")
               
               $xmlWriter.WriteElementString("maml:name","$($parameter.Name)")
               
               $xmlWriter.WriteStartElement("maml:description")
               $xmlWriter.WriteElementString("maml:para","Add description about the $($parameter.Name) parameter")
               $XmlWriter.WriteEndElement()
               
               $xmlWriter.WriteStartElement("command:parameterValue")
               $XmlWriter.WriteAttributeString("required", "true") 
               $XmlWriter.WriteAttributeString("variableLength", "false")
               $xmlWriter.WriteRaw("$($parameter.ParameterType)")
               $XmlWriter.WriteEndElement()

               $xmlWriter.WriteStartElement("dev:type")
               $xmlWriter.WriteElementString("maml:name","$($parameter.ParameterType)")
               $xmlWriter.WriteElementString("maml:uri","")
               $XmlWriter.WriteEndElement()

               $xmlWriter.WriteStartElement("dev:defaultValue")
               $XmlWriter.WriteEndElement()

            $XmlWriter.WriteEndElement()
            ##Closing the command:parameter tag
        }
        $XmlWriter.WriteEndElement()  
        ##Closing the command:parameters tag
    }
}
#generates parameterSets information
function Generate-CmdletParameterSets {  
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [System.Object]$CmdLetFunction)
    
    Begin {}
    Process {
        ##Creating the command:syntax subElement
        $xmlWriter.WriteStartElement("command:syntax")
        foreach ($pSets in $($CmdLetFunction.ParameterSets)) {
            #syntaxItem
            $xmlWriter.WriteStartElement("command:syntaxItem")
                #Name
                $xmlWriter.WriteElementString("maml:name","$($CmdLetFunction.Name)")
                #Parameters
                $pSetsParameters = $pSets.Parameters | Where { $_.Attributes -match "ArgumentType" }
                foreach ($parameter in $pSetsParameters) {
                    $xmlWriter.WriteStartElement("command:parameter")
                    $XmlWriter.WriteAttributeString("required", "$($parameter.IsMandatory)") 
                    $XmlWriter.WriteAttributeString("variableLength", "false") 
                    $XmlWriter.WriteAttributeString("globbing", "false")
                    $XmlWriter.WriteAttributeString("pipelineInput", "$($parameter.ValueFromPipeline)")
                    if($parameter.Position -eq "-2147483648") { $parameterPosition = "named" } else { $parameterPosition = $parameter.Position }
                    $XmlWriter.WriteAttributeString("position", "$parameterPosition")
                       
                       $xmlWriter.WriteElementString("maml:name","$($parameter.Name)")
                       
                       $xmlWriter.WriteStartElement("maml:description")
                       $xmlWriter.WriteElementString("maml:para","Add description about the $($parameter.Name) parameter")
                       $XmlWriter.WriteEndElement()
                       
                       $xmlWriter.WriteStartElement("command:parameterValue")
                       $XmlWriter.WriteAttributeString("required", "true") 
                       $XmlWriter.WriteAttributeString("variableLength", "false")
                       $xmlWriter.WriteRaw("$($parameter.ParameterType)")
                       $XmlWriter.WriteEndElement()
    
                    $XmlWriter.WriteEndElement()
                    ##Closing the command:parameter tag
                }
             $XmlWriter.WriteEndElement()
            #Closing the command:syntaxItem tag
        }
        $XmlWriter.WriteEndElement()  
        ##Closing the command:syntax tag
    }
    End {}
}
#generates INPUTS help
function Generate-CmdletInputTypes {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        ##Creating the command:inputTypes subElement
        $xmlWriter.WriteStartElement("command:inputTypes")
          $xmlWriter.WriteStartElement("command:inputType")
              $xmlWriter.WriteStartElement("dev:type")
                  $xmlWriter.WriteElementString("maml:name","")
                  $xmlWriter.WriteElementString("maml:uri","")
                  $xmlWriter.WriteElementString("maml:description","")
              $XmlWriter.WriteEndElement()
              $xmlWriter.WriteStartElement("maml:description")
                  $xmlWriter.WriteElementString("maml:para","You cannot pipe objects to this cmdlet.")
              $XmlWriter.WriteEndElement()
          $XmlWriter.WriteEndElement()
        $XmlWriter.WriteEndElement()  
        ##Closing the command:inputTypes tag
    }
}
#generates OUTPUTS help
function Generate-CmdletReturnValues {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        ##Creating the command:returnValues subElement
        $xmlWriter.WriteStartElement("command:returnValues")
          $xmlWriter.WriteStartElement("command:returnValue")
              $xmlWriter.WriteStartElement("dev:type")
                  $xmlWriter.WriteElementString("maml:name","Return Type of the function")
                  $xmlWriter.WriteElementString("maml:uri","")
                  $xmlWriter.WriteElementString("maml:description","")
              $XmlWriter.WriteEndElement()
              $xmlWriter.WriteStartElement("maml:description")
                  $xmlWriter.WriteElementString("maml:para","Add note on what this cmdlet returns")
              $XmlWriter.WriteEndElement()
          $XmlWriter.WriteEndElement()
        $XmlWriter.WriteEndElement()  
        ##Closing the command:returnValues tag
    }
}
#generates Terminating Errors Help Section
function Generate-CmdletTerminatingErrors {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        ##Creating the command:terminatingErrors subElement
        $xmlWriter.WriteStartElement("command:terminatingErrors")
        $XmlWriter.WriteEndElement()  
        ##Closing the command:terminatingErrors tag
    }
}
#generates Non Terminating Errors Help Section
function Generate-CmdletNonTerminatingErrors {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        ##Creating the command:nonTerminatingErrors subElement
        $xmlWriter.WriteStartElement("command:nonTerminatingErrors")
        $XmlWriter.WriteEndElement()  
        ##Closing the command:nonTerminatingErrors tag
    }
}
#generates Alert Set Help Section
function Generate-CmdletAlertSet {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Process {
        ##Creating the maml:alertSet subElement
        $xmlWriter.WriteStartElement("maml:alertSet")
        $xmlWriter.WriteElementString("maml:title","")
        $xmlWriter.WriteStartElement("maml:alert")
            $xmlWriter.WriteElementString("maml:para","")
        $XmlWriter.WriteEndElement()
        $XmlWriter.WriteEndElement()  
        ##Closing the maml:alertSet tag
    }
}
#generates examples in the NOTES section of help
function Generate-CmdletExamples {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Parameter(Mandatory)][System.Object]$CmdLetFunction,
    [Parameter(HelpMessage="The hashtable should have ExampleCode,ExampleDescription as its properties/keys")][System.Object[]]$ExampleObject)

    Process {
        ##Creating the examples subElement
        $xmlWriter.WriteStartElement("examples")
        #looping through Examples count to create the examples.The hashtable should have ExampleCode,ExampleDescription as its properties/keys
        For ($i=0; $i -lt $($ExampleObject.Count); $i++) {
            ##Starting example Tag  
            $xmlWriter.WriteStartElement("command:example") 
               $xmlWriter.WriteElementString("maml:title","--------------------------  Example $($i + 1)  --------------------------")
               $xmlWriter.WriteStartElement("maml:introduction")
                  $xmlWriter.WriteElementString("maml:para","PS C:\>")
               $XmlWriter.WriteEndElement()
               $xmlWriter.WriteElementString("dev:code","$($ExampleObject[$i].ExampleCode) 
               $($ExampleObject[$i].ExampleCodeResult)")
                                            
               $xmlWriter.WriteStartElement("dev:remarks")
                $xmlWriter.WriteElementString("maml:para","$($ExampleObject[$i].ExampleDescription)")
               $XmlWriter.WriteEndElement()
               
               $xmlWriter.WriteStartElement("command:commandLines")
               $xmlWriter.WriteStartElement("command:commandLine")
                   $xmlWriter.WriteStartElement("command:commandText")
                       $xmlWriter.WriteElementString("maml:para","")
                   $XmlWriter.WriteEndElement()
               $XmlWriter.WriteEndElement()
               $XmlWriter.WriteEndElement()

            $XmlWriter.WriteEndElement()
            ##Closing the command:example tag
        }
        $XmlWriter.WriteEndElement()  
        ##Closing the command:examples tag
    }
}
#generates Related Links help
function Generate-CmdletRelatedLinks {    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdLetFunction)

    Begin {
        $moduleOtherFunctions = Get-Command -Module $CmdLetFunction.ModuleName | Where { $_.Name -ne $CmdLetFunction.Name }
    }

    Process {
        ##Creating the maml:relatedLinks subElement
        $xmlWriter.WriteStartElement("maml:relatedLinks")
        if($moduleOtherFunctions.Count -gt 0) {
            foreach ($fn in $moduleOtherFunctions) {
                $xmlWriter.WriteStartElement("maml:navigationLink")
                    $xmlWriter.WriteElementString("maml:linkText","$($fn.Name)")
                    $xmlWriter.WriteElementString("maml:uri","")
                $XmlWriter.WriteEndElement()
            }
        }
        $XmlWriter.WriteEndElement()  
        ##Closing the maml:relatedLinks tag
    }
}

#endregion




#region updatable help helper functions

function Create-ModuleUpdatableHelp {
    
    [CmdletBinding()]
    Param([string]$ModuleName,
    [Parameter()][string]$HelpInfoUri)

    Begin {
        #language folder name
        $languageFolderName = "en-US"
        #Initial Logic - Import Module and load it in memory
        Import-Module -Name $ModuleName
        $module = Get-Module -Name $ModuleName
        if ($module) {
            $moduleBase = $module.ModuleBase
            $moduleType = $module.ModuleType
            $moduleScript = $module.ExportedFunctions
            $moduleAccessMode = $module.AccessMode

            if ($moduleType -eq "Script") { Write-Warning "Module needs to be of the type Manifest instead of Script." }
        }
        else {
            Write-Warning "$ModuleName does not exists or is not imported into the powershell session."
        }
    }
    Process {
        #manifest file path
        $manifestFilePath = "$($module.ModuleBase)\$ModuleBase.psd1"

        #region Create the folder on the IIS server
        $helpInfoUriArr = $HelpInfoUri.Split("//")
        $iisServerPsHelpPath = "\\$helpInfoUriArr[2]\c$\inetpub\wwwroot\$helpInfoUriArr[3]"
        if (-not (Test-Path -Path $iisServerPsHelpPath) ) { mkdir $iisServerPsHelpPath }
        #endregion 
        
        #Update the HelpInfoUri key of the manifest with the path to the PSHelp folder
        Update-ModuleManifest -Path $manifestFilePath -HelpInfoUri $HelpInfoUri
        
        #verifying the helpinfouri in the manifest
        $module = Import-Module $ModuleName -Force -PassThru
        if ($module.HelpInfoUri -ne $HelpInfoUri ) { "The helpInfoUri is not updated in the manifest of the module. please check..." }
        
        #Then we need to have the local xml file with the appropriate name present in the system because these files are going to get pushed up to the web server. 
        #Ensure the local XML help file is the right name. xml help file path is
        $localxmlhelpFilePath = "$($moduleBase)\$languageFolderName\$ModuleName.psm1-help.xml"
        $localXmlHelpFile = Get-Item -Path $localxmlhelpFilePath
        
        #Next, we need to create is the HelpInfo file. It is just an xml file which should be named as <Name of the module>_<GUID from the module manifest>_HelpInfo.xml
        $helpInfoFile = New-Item "C:\Test\$($module.Name)_$($module.Guid)_HelpInfo.xml" -Type File
        
        #Next, we need to update HelpInfo.xml file with the below xml content
        #The HelpContentUri should match the HelpInfoUri in the manifest of the module. 
        $helpInfoXmlContent = "<?xml version=`"1.0`" encoding=`"utf-8`"?>
        <HelpInfo xmlns=`"http://schemas.microsoft.com/powershell/help/2010/05`">
          <HelpContentURI>http:$HelpInfoUri/</HelpContentURI>
          <SupportedUICultures>
             <UICulture>
               <UICultureName>$languageFolderName</UICultureName>
               <UICultureVersion>3.2.15.0</UICultureVersion>
             </UICulture>    
          </SupportedUICultures>
        </HelpInfo>"
        
        Add-Content -Path $helpInfoFile -Value $helpInfoXmlContent
        
        #We now need to create a cabinet (CAB) file. Cab file name should be in the below format 
        #<Module Name>_<Module GUID>_<UICULTURE>_HelpContent.cab
        $cabFileName = "$($module.Name)_$($module.Guid)_$languageFolderName"+"_HelpContent.cab"
         
        #Now, put the xml help file and the HelpInfo xml file into the cab file. Now once you have created a cab file, there is no good way to do that in windows. Use the New-CabinetFile.ps1 file made from MakeCan.exe utility to do this.
        #Then, we will create a cab file locally by using the New-CabinetFile cmdlet with our xml file.
        ## Create a CAB file anywhere locally
        $cabFile = $localXmlHelpFile | New-CabinetFile -Name $cabFileName -DestinationPath 'C:\Test'
        iex $cabFile.FullName 
        
        #Copy the cab file and the HelpInfo xml to the web server.
        ## Copy the CAB file to the remote server
        copy $cabFile.FullName "$iisServerPsHelpPath"
        ## Copy the HelpInfo XML to the remote server
        copy $helpInfoFile.FullName "$iisServerPsHelpPath"
        
        #Modify the IIS Permissions
        #Enable the directory browsing on the PSHelp folder website on your IIS server and then verify it with the below command that it is accessible or not.
        #write a powershell script function to do it automatically for you if it is not already enabled.
        
        #Verifying the directory browing is enabled. below command when runs, shows the content of the issServerPath in the browser. 
        #if it shows the content then it is sccessfully enabled
        start http://labdc.lab.local/PSHelp/ 
        
        #Test your updatable help.
        ## Load the HelpInfo.xml
        Update-Help -Module $ModuleName -SourcePath "$iisServerPsHelpPath\" -Force

        ## Use Update-Help as normal
        Update-Help -Module $ModuleName -Force

        #Now you should have the updatable help.
    }
    End { }

    

}

function New-CabinetFile {
    <#
    .SYNOPSIS
        Creates a new cabinet .CAB file on disk.
    
    .DESCRIPTION
        This cmdlet creates a new cabinet .CAB file using MAKECAB.EXE and adds
        all the files specified to the cabinet file itself.
    
    .PARAMETER Name
        The output file name of the cabinet .CAB file, such as MyNewCabinet.cab.
        This should not be the entire file path, only the target file name.
    
    .PARAMETER File
        One or more file references that are to be added to the cabinet .CAB file.
        FileInfo objects (as generated by Get-Item etc) or strings can be passed
        in via the pipeline to be added to the cabinet file.
    
    .PARAMETER DestinationPath
        The output file path that the cabinet file will be saved in. It is also
        used for resolving any ambiguous file references, i.e. any file passed in
        via file name and not full path.
    
        If not specified the current working directory is used for the output file
        and attempting to resolve all ambiguous file references.
    
    .PARAMETER NoClobber
        Will not overwrite of an existing file. By default, if a file exists in the
        specified path, New-CabinetFile overwrites the file without warning.
    
    .EXAMPLE
        New-CabinetFile -Name MyCabinet.cab -File "File01.exe","File02.txt"
        
        This creates a new MyCabinet.cab file in the current directory and adds the File01.exe and File02.txt files to it, also from the current directory.
    .EXAMPLE
        Get-ChildItem C:\CabFile\ | New-CabinetFile -Name MyCabinet.cab -DestinationPath C:\Users\UserA\Documents
    
        This creates a new C:\Users\UserA\Documents\MyCabinet.cab file and adds all files within the C:\CabFile\ directory into it.
    #>

	[CmdletBinding()]
	Param (
		[Parameter(HelpMessage = "Target .CAB file name.", Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias("FilePath")]
		[string]$Name,
		
		[Parameter(HelpMessage = "File(s) to add to the .CAB.", Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias("FullName")]
		[string[]]$File,
		
		[Parameter(HelpMessage = "Default intput/output path.", Position = 2, ValueFromPipelineByPropertyName = $true)]
		[AllowNull()]
		[string[]]$DestinationPath,
		
		[Parameter(HelpMessage = "Do not overwrite any existing .cab file.")]
		[Switch]$NoClobber
	)
	
	Begin
	{
		
		## If $DestinationPath is blank, use the current directory by default
		if ($DestinationPath -eq $null) { $DestinationPath = (Get-Location).Path; }
		Write-Verbose "New-CabinetFile using default path '$DestinationPath'.";
		Write-Verbose "Creating target cabinet file '$(Join-Path $DestinationPath $Name)'.";
		
		## Test the -NoClobber switch
		if ($NoClobber)
		{
			## If file already exists then throw a terminating error
			if (Test-Path -Path (Join-Path $DestinationPath $Name)) { throw "Output file '$(Join-Path $DestinationPath $Name)' already exists."; }
		}
		
		## Cab files require a directive file, see 'http://msdn.microsoft.com/en-us/library/bb417343.aspx#dir_file_syntax' for more info
		$ddf = ";*** MakeCAB Directive file`r`n";
		$ddf += ";`r`n";
		$ddf += ".OPTION EXPLICIT`r`n";
		$ddf += ".Set CabinetNameTemplate=$Name`r`n";
		$ddf += ".Set DiskDirectory1=$DestinationPath`r`n";
		$ddf += ".Set MaxDiskSize=0`r`n";
		$ddf += ".Set Cabinet=on`r`n";
		$ddf += ".Set Compress=on`r`n";
		## Redirect the auto-generated Setup.rpt and Setup.inf files to the temp directory
		$ddf += ".Set RptFileName=$(Join-Path $ENV:TEMP "setup.rpt")`r`n";
		$ddf += ".Set InfFileName=$(Join-Path $ENV:TEMP "setup.inf")`r`n";
		
		## If -Verbose, echo the directive file
		if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
		{
			foreach ($ddfLine in $ddf -split [Environment]::NewLine)
			{
				Write-Verbose $ddfLine;
			}
		}
	}
	
	Process
	{
		
		## Enumerate all the files add to the cabinet directive file
		foreach ($fileToAdd in $File)
		{
			
			## Test whether the file is valid as given and is not a directory
			if (Test-Path $fileToAdd -PathType Leaf)
			{
				Write-Verbose """$fileToAdd""";
				$ddf += """$fileToAdd""`r`n";
			}
			## If not, try joining the $File with the (default) $DestinationPath
			elseif (Test-Path (Join-Path $DestinationPath $fileToAdd) -PathType Leaf)
			{
				Write-Verbose """$(Join-Path $DestinationPath $fileToAdd)""";
				$ddf += """$(Join-Path $DestinationPath $fileToAdd)""`r`n";
			}
			else { Write-Warning "File '$fileToAdd' is an invalid file or container object and has been ignored."; }
		}
	}
	
	End
	{
		
		$ddfFile = Join-Path $DestinationPath "$Name.ddf";
		$ddf | Out-File $ddfFile -Encoding ascii | Out-Null;
		
		Write-Verbose "Launching 'MakeCab /f ""$ddfFile""'.";
		$makeCab = Invoke-Expression "MakeCab /F ""$ddfFile""";
		
		## If Verbose, echo the MakeCab response/output
		if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
		{
			## Recreate the output as Verbose output
			foreach ($line in $makeCab -split [environment]::NewLine)
			{
				if ($line.Contains("ERROR:")) { throw $line; }
				else { Write-Verbose $line; }
			}
		}
		
		## Delete the temporary .ddf file
		Write-Verbose "Deleting the directive file '$ddfFile'.";
		Remove-Item $ddfFile;
		
		## Return the newly created .CAB FileInfo object to the pipeline
		Get-Item (Join-Path $DestinationPath $Name);
	}
}

#endregion