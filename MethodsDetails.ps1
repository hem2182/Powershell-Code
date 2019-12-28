$str = @"
public bool Method1 (string id,  List<Employee> employeeList,int code)
{
    var a = "This is the method body";
    var b = "This is another line";
    If(true)
    {
        var c = "This is if statement";
    }
    //this is a comment statement
    var d = 123;
}

//comment

private void Method2()
{
    //sample method 2
}

"@

Function Get-MethodsDetails {
    
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param([Parameter(Mandatory, ParameterSetName = "Path")][string]$CsharpFilePath,
    [Parameter(Mandatory, ParameterSetName = "Default")][string]$CsharpCodeString)

    Begin {
        if ($CsharpCodeString) {
            $lines = $CsharpCodeString.Split("`n")
        }
        elseif ($CsharpFilePath) {
            $lines = Get-Content -Path $CsharpFilePath
        }
        $methodsList = @()
        
        $methodBodyStart = $false
        $methodBodyEnd = $false
        $methodBody = ""
        $closingCurlyBraceFound = $false
        $closingTagPosition = 0
    }
    Process {
        for ($i=0; $i -lt $lines.Count; $i++) {
            
            if($lines[$i] -match '(?<AccessModifier>public|private|internal)\s*(?<ReturnType>[\w]+)\s*(?<MethodName>[\w]+)\s*\(?(?<Parameters>[^)]*)\)?'){
                $methodSignaure = $lines[$i]
                $accessModifier = $matches.AccessModifier
                $returnType = $matches.ReturnType
                $methodName = $matches.MethodName
                $parameters = $matches.Parameters
            }

            elseif($lines[$i] -match "{" -and -not $methodBodyStart){
                $methodBodyStart = $true
            }

            elseif ($lines[$i] -match "}" -and -not $methodBodyEnd) {
                $closingTagPosition = $i
                #### The below for loop finds the last closing tag position
            
                for ($j=$i + 1; $j -lt $lines.Count; $j++){
                    if($lines[$j] -match '(?<AccessModifier>public|private|internal)\s*(?<ReturnType>[\w]+)\s*(?<MethodName>[\w]+)\s*\(?(?<Parameters>[^)]*)\)?'){
                        break;
                    }
                    elseif ($lines[$j] -match "}") {
                        $closingTagPosition = $j
                    }
                }
            
                $closingCurlyBraceFound = $true
                $methodBodyEnd = $true
            
                #### adding the closing tag to method body if it is not the last closing tag
                if($closingTagPosition -ne $i) {
                    $methodBody += $lines[$i] + "`n"
                }
            }
            
            elseif ($methodBodyStart -and (!($methodBodyEnd) -or $i -lt $closingTagPosition)) {
                $methodBody += $lines[$i] + "`n"
            }
            
            #### Printing the results
            if ($methodBodyStart -and ($methodBodyEnd -and ($i -eq $closingTagPosition))) {
                $customObject = [PSCustomObject] @{
                    "MethodName"= $methodName
                    "ReturnType"= $returnType
                    "Parameters"= $parameters
                    "MethodSignature" = $methodSignaure
                    "MethodBody"= $methodBody
                }

                $methodsList += $customObject 

                # Resetting the flags
                $methodBodyStart = $false
                $methodBodyEnd = $false
                $methodBody = ""
                $closingCurlyBraceFound = $false
                $closingTagPosition = 0
            }
        }
    }
    End {
        return $methodsList
    }
}


$a = Get-MethodsDetails -CsharpCodeString $str
#$a = Get-MethodsDetails -CsharpFilePath "C:\Users\Hemant Sharma\Desktop\SampleCSharpCode.txt"