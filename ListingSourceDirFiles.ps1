﻿Function List-Files {

    [CmdletBinding()]
    Param([Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][int]$LineBreakupValue,
    [Parameter(Mandatory)][string]$Output)

    Begin {

        # Validating Source Path
        if (Test-Path -Path $Source -PathType Container -ErrorAction Ignore) {
            Write-Verbose "Valid Source Directory Path"
            if ((Get-ChildItem -Path $Source -Recurse -File).Count -eq 0) { Write-Output "Directory: $Source has no files" }
        } else {
            Write-Error "Invalid Source Directory. Please specify a directory path."
        }

        # Validating LineBreakupValue
        $minLineBreakupValue = 10
        if ($LineBreakupValue -lt $minLineBreakupValue) { Write-Error "LineBreakupValue determines the number of files created with each file having $LineBreakupValue values. It cannot be less than $minLineBreakupValue" -ErrorAction Stop}

        # Creating Output Path
        if (-NOT (Test-Path -Path $Output -PathType Container)) { 
            Write-Host "Creating Output Directory" 
            New-Item -Path $Output -ItemType Directory | Out-Null
        } else {
            Write-Verbose "Emptying Output Directory"
            Remove-Item -Path $Output -Force -Recurse
            New-Item -Path $Output -ItemType Directory | Out-Null
            New-Item -Path $Output -ItemType File -Name "ErrorLogs.txt"
        }

        $OutputFilesCount = [Math]::Ceiling((Get-ChildItem -Path $Source -Recurse -File).Count / $LineBreakupValue)
        Write-Verbose "$OutputFilesCount files will be created"
        
    }

    Process {
        $ErrorActionPreference = "Continue"
        For($i = 1; $i -le $OutputFilesCount; $i++) {
            $Filename = "Output_$i.txt"
            Write-Verbose "Creating File: $Filename"
            New-Item -Path $Output -Name $Filename -ItemType File | Out-Null
            Get-ChildItem -Path $Source -Recurse -File | Select FullName -Skip ($i*$LineBreakupValue -$LineBreakupValue) -First $LineBreakupValue | Foreach {
                try {
                    Add-Content -Path $Output\$Filename -Value $_.FullName -ErrorAction Stop
                } 
                catch {
                    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
                    $_.Exception.Message | Out-File "$Output\ErrorLogs.txt" -Append -Force
                }
                
            }
        }
    }

    End {
        Write-Output "Error Logs file created at path $Output\ErrorLogs.txt..."
        Write-Output "Task Complete..."

    }
}

List-Files -Source "E:\PersonalDocs" -Output "E:\Output" -LineBreakupValue 1000000