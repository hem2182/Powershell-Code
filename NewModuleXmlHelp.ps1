function New-ModuleXmlHelp {

    [CmdletBinding()]
    param([string]$ModuleName,
    [Parameter(ParameterSetName="Local")][switch]$Local,
    [Parameter(ParameterSetName="Updatable")][switch]$Updatable)

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

        #generates name and synopsis
        function Add-CmdletDetails {
            
            [CmdletBinding()]
            param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction)

            Process {
                $xmlWriter.WriteStartElement("command:details")
                $xmlWriter.WriteElementString("command:name","$($CmdLetFunction.Name)")
                $xmlWriter.WriteStartElement("maml:description")
                $xmlWriter.WriteElementString("maml:para","")
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
        #generates description
        function Add-CmdletDescription {
            
            [CmdletBinding()]
            param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction)

            Process {
                $xmlWriter.WriteStartElement("maml:description")
                $xmlWriter.WriteElementString("maml:para","The Add-CrmActivityToCrmRecord cmdlet lets you add an activity to a record. You use ActivityEntityType to specify Activity Type and Subject/Description to set values. 
                You can use Fields optional Parameter to specify additional Field values. Use @{&quot;field logical name&quot;=&quot;value&quot;} syntax to create Fields , and make sure you specify correct type of value for the field. 
                You can use Get-CrmEntityAttributeMetadata cmdlet and check AttributeType to see the field type. In addition, for CRM specific types, you can use New-CrmMoney, New-CrmOptionSetValue or New-CrmEntityReference cmdlets.")
                $xmlWriter.WriteElementString("maml:para","There are two ways to specify a target record.
                1. Pass EntityLogicalName and record&#39;s Id.
                2. Get a record object by using Get-CrmRecord/Get-CrmRecords cmdlets, and pass it.")
                $xmlWriter.WriteElementString("maml:para","You can specify note subject and body by using -Subject and -NoteText parameters.")
                $XmlWriter.WriteEndElement()
            }
        }
        #generates syntax
        function Add-CmdletParameterSets {
            
            [CmdletBinding()]
            param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction)

            Process {
                ##Creating the command:syntax subElement
                $xmlWriter.WriteStartElement("command:syntax")
                foreach ($pSets in $($CmdLetFunction.ParameterSets)) {
                    #region syntaxItem
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
                               $xmlWriter.WriteElementString("maml:para","A connection to your CRM organization. Use `$conn = Get-CrmConnection &lt;Parameters&gt; to generate it.")
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
        }
        #generates parameter information
        function Add-CmdletParameters {
            
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
                       $xmlWriter.WriteElementString("maml:para","A connection to your CRM organization. Use `$conn = Get-CrmConnection &lt;Parameters&gt; to generate it.")
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
        #generates INPUTS help
        function Add-CmdletInputTypes {
            
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
                          $xmlWriter.WriteElementString("maml:para","")
                      $XmlWriter.WriteEndElement()
                  $XmlWriter.WriteEndElement()
                $XmlWriter.WriteEndElement()  
                ##Closing the command:inputTypes tag
            }
        }
        #generates OUTPUTS help
        function Add-CmdletReturnValues {
            
            [CmdletBinding()]
            param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction)

            Process {
                ##Creating the command:returnValues subElement
                $xmlWriter.WriteStartElement("command:returnValues")
                  $xmlWriter.WriteStartElement("command:returnValue")
                      $xmlWriter.WriteStartElement("dev:type")
                          $xmlWriter.WriteElementString("maml:name","")
                          $xmlWriter.WriteElementString("maml:uri","")
                          $xmlWriter.WriteElementString("maml:description","")
                      $XmlWriter.WriteEndElement()
                      $xmlWriter.WriteStartElement("maml:description")
                          $xmlWriter.WriteElementString("maml:para","")
                      $XmlWriter.WriteEndElement()
                  $XmlWriter.WriteEndElement()
                $XmlWriter.WriteEndElement()  
                ##Closing the command:returnValues tag
            }
        }
        function Add-CmdletTerminatingErrors {
            
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
        function Add-CmdletNonTerminatingErrors {
            
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
        function Add-CmdletAlertSet {
            
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
        function Add-CmdletExamples {
            
            [CmdletBinding()]
            param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction,
            [Int]$ExamplesCount,
            [System.Management.Automation.PSCustomObject[]]$ExampleObject)

            Process {
                ##Creating the command:examples subElement
                $xmlWriter.WriteStartElement("command:examples")
                #looping through Examples count to create the examples. The ExampleObject should have the same number of object array as the count
                For ($i=0; $i -le $ExamplesCount; $i++) {
                    ##Starting example Tag  
                    $xmlWriter.WriteStartElement("command:example") 
                        $xmlWriter.WriteElementString("maml:title","--------------------------  Example $($i + 1)  --------------------------")
                        $xmlWriter.WriteStartElement("maml:introduction")
                           $xmlWriter.WriteElementString("maml:paragraph","PS C:\&gt;")
                        $XmlWriter.WriteEndElement()
                        $xmlWriter.WriteElementString("dev:code","$($ExampleObject[$i].ExampleCode)")
                                                     
                       $xmlWriter.WriteStartElement("dev:remarks")
                       $xmlWriter.WriteElementString("maml:para","$($ExampleObject[$i].ExampleDescriptionLine1)")
                       $xmlWriter.WriteElementString("maml:para","$($ExampleObject[$i].ExampleDescriptionLine2)")
                       $xmlWriter.WriteElementString("maml:para","$($ExampleObject[$i].ExampleDescriptionLine3)")
                       $xmlWriter.WriteElementString("maml:para","$($ExampleObject[$i].ExampleDescriptionLine4)")
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
        function Add-CmdletRelatedLinks {
            
            [CmdletBinding()]
            param([System.Xml.XmlTextWriter]$XmlWriter,
            [Object]$CmdLetFunction)

            Process {
                ##Creating the maml:relatedLinks subElement
                $xmlWriter.WriteStartElement("maml:relatedLinks")
                $XmlWriter.WriteEndElement()  
                ##Closing the maml:relatedLinks tag
            }
        }
    }
    Process {
        
        #### If Manifest module is found, start creating module xml help
        ## The xml file needs to go in a language specific folder with a specific name. See what options you have for the language folder. Create the folder --We are using english
        if (!(Test-Path -Path "$($moduleBase)\en-US")) {
            $languageFolder = New-Item "$($moduleBase)\en-US" -ItemType Directory -Force
            $languageFolder
        }

        ## Create the xml file in the language folder with name as <ModuleName.psm1-help.xml> with the basic xml
        if (!(Test-Path -Path "$languageFolder\$ModuleName.psm1-help.xml")) {
            New-Item "$languageFolder\$ModuleName.psm1-help.xml" -ItemType File -Force
        }

        ## Getting all the function details from the module
        $exportedFunctions = $module.ExportedFunctions.Values | Select *

        ## Creating basic XML file structure with root node
        $filePath = "C:\Test\new.xml" 
        $xmlWriter = New-Object System.XMl.XmlTextWriter($filePath,$Null)
        $xmlWriter.Formatting = "Indented"   
        $XmlWriter.IndentChar = "`t" 
        $xmlWriter.WriteStartDocument() 		                #Write the XML decaration
        $xmlWriter.WriteStartElement("helpItems")               #Root element
        $XmlWriter.WriteComment("all commands xml gos here")	#Adds comments directly into the xml file.

        ## Filling xml with the cmdlets help command:command nodes
        foreach($function in $exportedFunctions) {

            #creating the command:command root element
            $xmlWriter.WriteStartElement("command:command") 
            $XmlWriter.WriteAttributeString("xmlns:maml", "http://schemas.microsoft.com/maml/2004/10") 
            $XmlWriter.WriteAttributeString("xmlns:command", "http://schemas.microsoft.com/maml/dev/command/2004/10") 
            $XmlWriter.WriteAttributeString("xmlns:dev", "http://schemas.microsoft.com/maml/dev/2004/10")
            $XmlWriter.WriteAttributeString("xmlns:MSHelp", "http://msdn.microsoft.com/mshelp")
            
            #Add-CmdletXMLHelp -XmlWriter $xmlWriter -CmdletFunction $function
              #create the command:details node
                Add-CmdletDetails -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the maml:description node
                Add-CmdletDescription -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:parameterSets node
                Add-CmdletParameterSets -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:parameters node
                Add-CmdletParameters -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:inputTypes node
                Add-CmdletInputTypes -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:returnValues node
                Add-CmdletReturnValues -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:terminatingErrors node
                Add-CmdletTerminatingErrors -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:nonTerminatingErrors node
                Add-CmdletNonTerminatingErrors -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the maml:alertSet node
                Add-CmdletAlertSet -XmlWriter $xmlWriter -CmdLetFunction $function
              #create the command:examples node
                $examplesObj = @()
                $exampleObject = New-Object System.Management.Automation.PSCustomObject @{
                    "ExampleCode" = ""
                    "ExampleDescriptionLine1" = ""
                    "ExampleDescriptionLine2" = ""
                    "ExampleDescriptionLine3" = ""
                    "ExampleDescriptionLine4" = ""

                }
                $examplesObj += $exampleObject
                Add-CmdletExamples -XmlWriter $xmlWriter -CmdLetFunction $function -ExamplesCount 4 -ExampleObject $exampleObject
              #create the maml:relatedLinks node
                Add-CmdletRelatedLinks -XmlWriter $xmlWriter -CmdLetFunction $function
            
            #closing the command root element
            $XmlWriter.WriteEndElement() 
            #Closed the command:command tag
        }

        $xmlWriter.WriteEndElement()                            #Closing the helpItems tag
        $xmlWriter.WriteEndDocument()                           #Closing the xml document
        $xmlWriter.Flush()                                      #Clearing it from memory
        $xmlWriter.Close()                                      #Closing the xml document
    }
    End {
    }
}

function Add-CmdletXMLHelp {
    
    [CmdletBinding()]
    param([System.Xml.XmlTextWriter]$XmlWriter,
    [Object]$CmdletFunction) 

    Begin {
        $cmdletDetails = $CmdletFunction | Select * 

        ## Loading the xml file
        $module = Get-Module -Name $cmdletDetails.ModuleName
        [xml]$xmlFile = Get-Content -Path "C:\Test\new.xml"

        
    }
    Process {
        

        Add-HelpCmdletDetails -XmlFile $xmlFile

        #appending the command help element to the helpItems xml node
        $xmlFile.helpItems.AppendChild($commandEle);
    }
    End {}
}


function Generate-XmlHelpContent {
    
    [CmdletBinding()]
    param([System.Object]$FunctionDetail)

    Begin {
        
        $maml = "http://schemas.microsoft.com/maml/2004/10"
        $command = "http://schemas.microsoft.com/maml/dev/command/2004/10"
        $dev = "http://schemas.microsoft.com/maml/dev/2004/10"

        $parameterReq = $true
        $parameterGlobbing = $false
        $parameterPipelineInput = $false
        $parameterPosition = "named"
        $parameterAliases = ""

        $parameterValueReq = $true

        
    }
    Process {
        $commandTag = "
        <command:command xmlns:dev=$dev xmlns:command=$command xmlns:maml=$maml>
        <! Command>
        	<command:details>
        		<command:name>$($FunctionDetail.Name)</command:name>
        		<maml:description>
        			<maml:para>$($FunctionDetail.Name) Synopsis</maml:para>
        		</maml:description>
        		<maml:copyright>
        			<maml:para> </maml:para>
        		</maml:copyright>
        		<command:verb>$($FunctionDetail.Verb)</command:verb>
        		<command:noun>$($FunctionDetail.Noun)</command:noun>
        		<dev:version/>
        	</command:details>
        	<maml:description>
        		<maml:para>This is $($FunctionDetail.Name) description</maml:para>
        	</maml:description>
        	<command:syntax>
        		<! Parameter Sets>
        	</command:syntax>
        	<command:parameters>
        		<! All Parameters>
        		<command:parameter aliases=$parameterAliases position=$parameterPosition pipelineInput=$parameterPipelineInput globbing=$parameterGlobbing required=$parameterReq>
        			<maml:name>Name</maml:name>
        			<maml:description>
        				<maml:para>This is the name parameter description.</maml:para>
        			</maml:description>
        			<command:parameterValue required=$parameterValueReq>string</command:parameterValue>
        			<dev:defaultValue> </dev:defaultValue>
        		</command:parameter>
        	</command:parameters>
        	<command:examples>
            <! Examples>
        	    <command:example>
        	    <maml:title> EXAMPLE 1 </maml:title>
        	    <maml:introduction>
        	    	<maml:para> </maml:para>
        	    </maml:introduction>
        	    <dev:code>PS C:\&gt; $($FunctionDetail.Name) Name MYVM</dev:code>
        	    <dev:remarks>
        	    	<maml:para>This example creates a new VM called MYVM.</maml:para>
        	    </dev:remarks>
        	    </command:example>
            </command:examples>
        </command:command>"
    }
    End {
        return $commandTag
    }
}