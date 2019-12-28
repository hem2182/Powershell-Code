
function Add-CmdletXMLHelp {
    
    [CmdletBinding()]
    param([System.Object]$CmdletFunction)

    Begin {
        
        $maml = "&quot;http://schemas.microsoft.com/maml/2004/10&quot;"
        $command = "&quot;http://schemas.microsoft.com/maml/dev/command/2004/10&quot;"
        $dev = "&quot;http://schemas.microsoft.com/maml/dev/2004/10&quot;"
        $mshelp = "&quot;http://msdn.microsoft.com/mshelp&quot;"

        $parameterReq = $true
        $parameterGlobbing = $false
        $parameterPipelineInput = $false
        $parameterPosition = "named"
        $parameterAliases = ""

        $parameterValueReq = $true

        
    }
    Process {
        $commandTag = "
        <command:command xmlns:dev=$dev xmlns:command=$command xmlns:maml=$maml xmlns:MSHelp=$mshelp>
        	<command:details>
			    <command:name>$($CmdletFunction.Name)</command:name>
			    <maml:description>
			    	<maml:para />
			    </maml:description>
			    <maml:copyright>
			    	<maml:para />
			    </maml:copyright>
			    <command:verb>$($CmdletFunction.Verb)</command:verb>
			    <command:noun>$($CmdletFunction.Noun)</command:noun>
			    <dev:version />
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
#Tested
function Generate-ModuleManifest {
    
    [CmdletBinding()]
    param([string]$ModuleName,
    [string]$Author,
    [string]$CompantName,
    [string]$ModuleDescription)

    Begin {
        $module = Get-Module -Name $ModuleName -ListAvailable
        if ($module) {
            $moduleBase = $module.ModuleBase
            $moduleType = $module.ModuleType
            $moduleScript = $module.ExportedFunctions
            $moduleAccessMode = $module.AccessMode
        }
        else {
            Write-Warning "$ModuleName does not exists."
        }
    }
    Process {
        if ($moduleType -eq "Manifest") { Write-Output "A manifest for this module already exists. If you are updating it, try Update-ModuleManifest -ModuleName $ModuleName" }
        else {
            #Creating a Manifest for the Module
            $params = @{
            'Author' = $Author
            'CompanyName' = $CompantName
            'Description' = $ModuleDescription
            'NestedModules' = $ModuleName ## this is required to expose functions in a manifest module
            'Path' = "$moduleBase\$ModuleName.psd1" ##Use the same name as the module witha psd1 extension
            }
            New-ModuleManifest @params
        }
    }
    End {
        #Verifying Manifest is successfully created.
        $manifestExists = (Get-Item "$moduleBase\$ModuleName.psd1" -ErrorAction SilentlyContinue).Count -gt 0
        if ($manifestExists) { Write-Verbose "Manifest for the Module:$ModuleName is created successfully."}
        else { Write-Warning "Manifest for Module: $ModuleName is not found."} 
    }
}

function New-ModuleLocalXmlHelp {
    [CmdletBinding()]
    param([string]$ModuleName)

    Begin {
        #Initial Logic
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

        $xmlInitialTagValue = '<?xml version="1.0" encoding="utf-8"?>
<helpItems schema="maml">'
        $xmlEndTagValue = '
</helpItems>'

        #### If Manifest module is found, start creating module xml help
        ## The xml file needs to go in a language specific folder with a specific name. See what options you have for the language folder. Create the folder --We are using english
        if (!(Test-Path -Path "$($moduleBase)\en-US")) {
            $languageFolder = New-Item "$($moduleBase)\en-US" -ItemType Directory -Force
            $languageFolder
        }

        ## Create the xml file in the language folder with name as <ModuleName.psm1-help.xml> with the basic xml
        if (!(Test-Path -Path "$languageFolder\$ModuleName.psm1-help.xml")) {
            New-Item "$languageFolder\$ModuleName.psm1-help.xml" -ItemType File -Value $xmlInitialTagValue -Force
        }

        ## Write logic to get xml code for functions help
        $exportedFunctions = $module.ExportedFunctions.Values | Select *
        #$helpContentList = New-Object [System.COllections.ArrayList]

        foreach($function in $exportedFunctions) {
            $functnDetails = $function | Select * 
            $content = Add-CmdletXMLHelp -FunctionDetail $functnDetails
            Add-Content -Path "$languageFolder\$ModuleName.psm1-help.xml" -Value $content

        }
        Add-Content -Path "$languageFolder\$ModuleName.psm1-help.xml" -Value $xmlEndTagValue
    }
    End {}
}

function New-ModuleUpdatableXmlHelp {
    [CmdletBinding()]
    param()

    Begin {}
    Process {}
    End {}
}