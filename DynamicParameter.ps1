function Sample-Cmdlet {
    [CmdletBinding()]
    Param([string]$ModuleName)

    DynamicParam {
        $attributes = new-object System.Management.Automation.ParameterAttribute
        $attributes.Mandatory = $false

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
}