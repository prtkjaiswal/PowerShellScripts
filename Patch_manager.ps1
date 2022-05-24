# Script		:	Patch_Manager_v5.ps1
# Version		:	5.0
# Description	:	This PowerShell Script Provides a Menu - Driven way to Apply WebLogic PSUs, Tuxedo RP and OPatch Upgrade 
# Usage			:  	.\<script_location>\Patch_Manager_v2.ps1		(Run Powershell as Admin)
# Version Edits	: 	
#					


#BEGIN-SCRIPT

 enum Outcome
{
    Continue
    Quit
}
 
 Class Opatch_Manager {
	 
	 [int]$count
	 [string]$val
	 [string]$JdkExePath
	 [string]$JdkInstPath
	 [string]$JreInstPath
	 [string]$JdkInstArgs
	 [string]$result
	 [string]$temp
	 [string]$choice
	 [string]$inchoice
	 [string]$command
	 [string]$expression
	 [string]$dttm
	 [string]$LogFile
	 [string]$TempFile
	 [string]$Stamp
	 [string]$LogMessage 
	 [string]$passvalue
	 [string]$tuxpath
	 [string]$weblogicpath	
	 [string]$lspatches
	 [string]$version
	 [string]$patchapply
	 [string]$serivestatus
	 [string]$ser1
	 [string]$ser2
	 [string]$ser3
	 [string]$tmpservice
	 [string]$javahome
	 [string]$weblogichome
	 [string]$new_ver
	 [string]$prev_ver	
	 [string]$tux_patch_path
	 [string]$web_patch_path
	 [string]$opatch_patch_path
	 [string]$JDK_patch_path
		
	ShowLogo(){
		 $this.WriteLog(" `n`n"													)
		 $this.WriteLog("                _____"                   )
		 $this.WriteLog("               / ___\ "                   )
		 $this.WriteLog("               \___ \ "                   )
		 $this.WriteLog("                ___) |"                   )
		 $this.WriteLog("               |____/  "                   )
		 $this.WriteLog(""                                                      )
		 $this.WriteLog("   P A T C H    M A N A G E M E N T    S C R I P T "   )
		 $this.WriteLog(""                                                      )
	}
	
    REPL() {
		$this.javahome = $env:JAVA_HOME + "\bin\java.exe"
		$this.tuxpath = ($env:TUXDIR | foreach-object {$_.split("1")[0]} | foreach-object { $_.Substring(0,$_.Length-7)}) + "\OPatch\opatch.bat"
		$this.weblogicpath = ($env:TUXDIR | foreach-object {$_.split("1")[0]} | foreach-object { $_.Substring(0,$_.Length-14)}) + "\weblogic\Opatch\opatch.bat"
		$this.weblogichome = ($env:TUXDIR | foreach-object {$_.split("1")[0]} | foreach-object { $_.Substring(0,$_.Length-14)}) + "\weblogic"
		#$this.weblogicpath = ($env:TUXDIR | foreach-object {$_.split("1")[0]} | foreach-object { $_.Substring(0,$_.Length-14)}) + "\Opatch\opatch.bat"
		#$this.weblogichome = ($env:TUXDIR | foreach-object {$_.split("1")[0]} | foreach-object { $_.Substring(0,$_.Length-14)})
		

		
		$this.lspatches = "lspatches"
		$this.version = "version"
		$this.patchapply = "apply"
		$this.dttm = Get-Date -format s  | ForEach-Object { $_ -replace ":", "" }
		$this.LogFile = "D:\temp\PatchLog\Log_"+$this.dttm+".log"
		$this.TempFile = "D:\temp\PatchLog\temp.log"

		$this.tux_patch_path = "D:\temp\Patches\TuxedoPatch\"
		$this.opatch_patch_path = "D:\temp\Patches\OPatch\"
		$this.web_patch_path = "D:\temp\patches\WeblogicPatch_"+$this.dttm
		$this.JDK_patch_path = "D:\temp\patches\JDKPatch_"+$this.dttm+"\"

		#$this.tux_patch_path = "\\<server.com>.com\Patches\TuxedoPatch"
		#$this.opatch_patch_path = "\\<server.com>\Patches\Opatch"
		#$this.web_patch_path = "\\<server.com>\Patches\WeblogicPatch"

        while($this.ShowMenu() -eq 'Continue' -and $this.Eval() -eq 'Continue'){
            $this.Print()
        }
    }
	
	CallAnimate()
	{
		$this.count = 0
		Write-Host "`n`n"
		Write-Host "       " -nonewline  
		do {
			Start-Sleep -Milliseconds 900 ; 
			Write-Host "--------" -nonewline
			$this.count++			
		} until ($this.count -eq 11)

		Write-Host "`n" 
	}


	[bool] CheckJDK($val)
	{
				# Here we will first check JDK is installed or not
				# If not installed then display a message accordingly
				# Display the version if JDK is present

				# $error variable contains the list of all the recent error messages
				# We will search for JDK using Get-packages
				# If it is not installed, the error message will be stored in $error
				# Before this ,we will clear the contents of $error to make it blank
				
				# Now if JDK is installed already, noting will go in $error, but at the same  time, $temp will contain the details of JDK package
				# Hence $error.length = 0 and $temp.length != 0

				# If JDK is not installed, get-package will returmn error, it will be stored in $error and nothing will go in $temp
				# Hence $error.length != 0 and $temp.length = 0
				
				$error.clear()
				$this.temp = get-package '*java 8*' -ErrorAction SilentlyContinue | Out-String
				
				if ($val -eq 0)
				{
					if ($this.temp.length -eq 0 -AND  $error.length -ne 0 ) {return $false}
					else {return $true}
				}
				else 
				{
					if ($this.temp.length -eq 0 -AND  $error.length -ne 0 )
					{
						Write-host "`n"
						$this.WriteLog("Seems like JDK is not INSTALLED in the System~")
						return $False	
					}

					else  # JDK is Present
					{
						# Here We will check for the version of JDK
						# IF ther are more than one Version of JDK installed, we will dispaly appropriate message to the User
						# To Accomplish this, we wil get the output of Get-Package in a file -> $this.TempFile
						# Remove the blank lines from the File		

						# Removing the file if it exists
						Remove-Item  $this.TempFile

						# Creating the file to hold the result of Get-Package Data
						If (!(Test-Path $this.TempFile)) {New-Item -Path $this.TempFile -Force}
						Add-content $this.TempFile -Value $this.temp
	
						# Removing Blank lines from TempFile
						# The parenthesis causes the get-content command to finish before proceeding through the pipeline. 
						# Without the parenthesis, the file would be locked and we couldn't write back to it.
						(Get-Content $this.TempFile) | ? {$_.trim() -ne "" } | set-content $this.TempFile

						# If just one jdk is installed, the File will have just 3 lines, but if more than one JDK is installed, the file will  more than 3 lines
						# Hence if the file has 3+ lines ,we will conclude that there are more than one JDK istalled
						
						if ((Get-Content $this.TempFile).length -gt 3)
						{
							$this.WriteLog("CAUTION!! You have more than one Versions of JDK installed!")
							$this.temp = Get-Content $this.TempFile 
							$this.WriteLog($this.temp)
						}
						else 
						{
							$this.temp = Get-Content $this.TempFile
							Write-Host "`n"
							$this.WriteLog("The Current Version of Installed Java JDK is :")  
							Write-Host "`n"
							$this.WriteLog($this.temp)
						}  	

						Remove-Item  $this.TempFile
					
						return $True
					}
			}
		
	}

	[String] InstallJDK()
	{

		
		Write-Host "`n       Default Path for JDK Setup file is : " -nonewline
		Write-Host " \\<server.com>\temp\Software\PSU\JDK\Latest" -fore Yellow

		$this.val = Read-Host "`n       Proceed with Default Path ? (Y/N)  "	
		
		if ($this.val -eq 'n')
		{
			Write-Host "`n"
			$this.JdkExePath = Read-Host "`n       Enter the complete path of JDK Setup EXE File "
			Write-Host "`n"
			$this.passvalue = "`n       Entered Path is : " + $this.JdkExePath 
			$this.WriteLog($this.passvalue)

			if(Test-Path $this.JdkExePath -PathType Leaf)    					 	#-PathType Leaf part tells the cmdlet to check for
			{																		# a file and not a directory explicitly.
				$this.WriteLog("Checking if the File Exist `t`t`t PASSED `n")	
			}
			else 
			{ 
				$this.WriteLog("The file does not exists in the Entered Path ^")   	# IN the WriteLog Function we have used ^ in the Switch Block 
				Write-Host ""														# to display the lines in Red with White bckgrnd
				$this.WriteLog("Please Enter a valid File path and try again ^ ")	# We will Add ^ in the end of the line, and it will get printed in Yellow
				$this.ShowJava()													# However, ^ will not be printed
			}
	
		}
		elseif ($this.val -eq 'y')
		{
				
				Write-Host "`n       Proceeding with default Path...`n"
				Write-Host "`n       Looking for the latest JDK Zip file in below Folder :"
				Write-Host "`n       \\<server.com>\Temp\Software\PSU\JDK\Latest" -fore Yellow -NoNewline
				

				if ( (get-childitem \\<server.com>\Temp\Software\PSU\JDK\Latest | Measure-object).count -ne 1)
				{
					Write-Host "`t`tFAILED" -fore Red -back White
					Write-Host "`n       CAUTION : The Folder has more than one item."
					Write-Host "`n       		   Please make sure that the folder only contains one latest JDK Zip File"
					$this.ShowJava()
				}
				elseif ([System.IO.Path]::GetExtension((get-childitem \\<server.com>\Temp\Software\PSU\JDK\Latest).Name) -ne '.zip')
				{
					Write-Host "`t`tFAILED" -fore Red -back White
					Write-Host "`n       CAUTION : The Folder does not contain any .zip file"
					Write-Host "`n       		   Please make sure that the folder contains latest JDK Zip File"
					$this.ShowJava()
				}
				else {
					Write-Host "`t`t`t PASSED" -fore Green
				}


				If (!(Test-Path $this.JDK_patch_path)) 
				{
					New-Item -Path $this.JDK_patch_path -ItemType "directory" -Force
				}

				Write-Host "`n       Copying ZIP file from Shared path to the Server"
				Write-Host "`n       Source : \\<server.com>\Temp\Software\PSU\JDK\Latest" -fore Yellow
				Write-Host "`n       Target : "$this.JDK_patch_path -fore Yellow

				Copy-Item "\\<server.com>\Temp\Software\PSU\JDK\Latest\*" -Destination $this.JDK_patch_path

				if(!($?))
				{
					Write-Host "`n       CAUTION : There were some issue while Copying the JDK Zip file."
					Write-Host "`n                 Please validate the copied ZIP file and continue again."
					$this.ShowJava()
				}

				Write-Host "`n       Copying Zip File Status " -NoNewline
				Write-Host "`t`t`t`t`t`t`t`t PASSED" -Fore Green


				Write-Host "`n       Unzipping the JDK Zip file under the below Folder :"
				Write-Host "`n       "$this.JDK_patch_path -fore Yellow

				$this.val = (Get-ChildItem $this.JDK_patch_path).Name
				
				Set-Location $this.JDK_patch_path
			    jar.exe -xvf $this.val

				if(!($?))
				{
					Write-Host "`n       CAUTION : There were some issue while unzipping the JDK Zip file."
					Write-Host "`n                 Please validate the extracted files and continue again."
					$this.ShowJava()
				}

				Write-Host "`n       Unzip Status " -NoNewline
				Write-Host "`t`t`t`t`t`t`t`t`t PASSED" -Fore Green

				Write-Host "`n       Removing the .zip file " -NoNewline

				del $this.val

				if(!($?))
				{
					Write-Host "`n       CAUTION : There were some issues while deleting the JDK Zip file."
					Write-Host "`n                 Please validate the files and continue again."
					$this.ShowJava()
				}				

				else 
				{
					Write-Host "`t`t`t`t`t`t`t`t PASSED" -Fore Green
				}

				$this.JdkExePath = (Get-ChildItem -Recurse -Include *.exe).Name



		}
		else 
		{
			Write-Host "`n       Invalid Input. Please try again!"
			$this.ShowJava()	
		}

		$this.temp = Read-Host "`n       Enter the Release of JDK 8 which is being Installed (Ex. 311,321 etc) "

		$this.JdkInstPath = "D:\Apps\bea\JDK1.8.0_"+$this.temp
		$this.JreInstPath = "D:\Apps\bea\JRE1.8.0_"+$this.temp

		Write-Host "`n"	
		$this.WriteLog("The Paths generated for JDK and JRE Installation are :")
		Write-Host "`n"
		$this.WriteLog("JDK : "+$this.JdkInstPath + " ~")						# IN the WriteLog Function we have used ~ in the Switch Block 
		Write-Host "`n"															# to display the lines in Red with White bckgrnd
		$this.WriteLog("JRE : "+$this.JreInstPath + " ~")						# We will Add ~ in the end of the line, and it will get printed in Yellow
		Write-Host "`n"															# However, ~ will not be printed
		$this.temp = Read-Host "`n       Are you happy with above Paths ? (Y/N) "

		while ($this.temp -ne 'Y')
		{
			$this.WriteLog("`nPlease Enter the Path where you want Install JDk and JRE below :")
			$this.JdkInstPath = Read-Host "`n       JDK "
			$this.JdkInstPath = Read-Host "`n       JRE "
			Write-Host "`n"	
			$this.WriteLog("The Paths generated as per your Input are :")
			Write-Host "`n"
			$this.WriteLog("JDK : "+$this.JdkInstPath + " ~")						# IN the WriteLog Function we have used ~ in the Switch Block 
			Write-Host "`n"															# to display the lines in Red with White bckgrnd
			$this.WriteLog("JRE : "+$this.JreInstPath + " ~")						# We will Add ~ in the end of the line, and it will get printed in Yellow
			Write-Host "`n"															# However, ~ will not be printed
			$this.temp = Read-Host "`n       Are you happy with above Paths ? (Y/N) "
		}

		Write-Host "`n"	
		$this.WriteLog("Proceeding with JDK Installation..")
		# When we proceed with Java install There are following steps
		# 1) Run the installation Command
		# THe below statment, it will not only run the EXE file , but also, return the Process Details in $procDetails variable, which can be used later, to get the status.
		#$procDetails = Start-Process -FilePath 'D:\Software\JDK1.8.0_321\jdk-8u321-windows-x64.exe' -ArgumentList '/s INSTALLDIR=D:\Apps\bea\JDK1.8.0_321 /INSTALLDIRPUBJRE=D:\Apps\bea\JRE1.8.0_321 /LV* D:\Temp\PatchLog\JDK_Install_log.log' -Passthru
		#$procDetails = Start-Process -FilePath 'D:\Software\JDK1.8.0_311\jdk-8u311-windows-x64.exe' -ArgumentList '/s INSTALLDIR=D:\Apps\bea\JDK1.8.0_311 /INSTALLDIRPUBJRE=D:\Apps\bea\JRE1.8.0_311 /LV* D:\Temp\PatchLog\JDK_Install_log.log' -Passthru
		
		# Creating the Parameters if the Start-Process Command

		Remove-Item  D:\Temp\PatchLog\JDK_Install_log.log

		$this.JdkInstArgs = "/s INSTALLDIR="+$this.JdkInstPath+" /INSTALLDIRPUBJRE="+$this.JreInstPath+" /LV* D:\Temp\PatchLog\JDK_Install_log.log"
		#Write-Host $this.JdkExePath
		#Write-Host $this.JdkInstArgs

		$procDetails = Start-Process -FilePath $this.JdkExePath -ArgumentList $this.JdkInstArgs -Passthru
		
		# 2) Grab the Process id from the installation process and moniton until when it is running. Get the stauts of running in #status
		$status = get-process | where-object { $_.id -eq $procDetails.id }				

		# 3) Show the status while the process is still runing. Once the process completes, the $status will return NULL
		While($status -ne $null)
		{
			$status = get-process | where-object { $_.id -eq $procDetails.id }
			$this.CallAnimate()
			Write-Host "`n"
		}

		# 4) Analyse the File and decide whether it was a success or failure
		# a) Get content of the installation log
		# b) Get the last 10 lines only, since the log is huge and we do not want any over head
		# c) Get the line which contain the string : '*Installation operation completed successfully*'
		# The Entire line very is long , we need to extract only Relevant String from it
		# MSI (s) (CC:3C) [04:02:40:760]: Product: Java SE Development Kit 8 Update 321 (64-bit) -- Installation operation completed successfully.
		# We will use 'Product' as delimiter, and extract Substring  
		# IndexOf('Product') will return the Index of Character P. From here we will have to add number of remaining character ie. roduct: PLus one Space ie. 9 
		# Hence to get the extact line we will use : $validateLog = $validateLog.SubString($validateLog.IndexOf('Product') + 9)

		$validateLog = Get-Content D:\Temp\PatchLog\JDK_Install_log.log | Select-Object -Last 10 | Where-Object {$_ -like '*Installation operation completed successfully*'}
		$validateLog = $validateLog.SubString($validateLog.IndexOf('Product') + 9)
		$this.WriteLog($validateLog)

		return $this.JdkInstPath

	}
	
	[String] WriteLog([string]$LogString)
	{
		$this.Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
		$this.LogMessage = $this.Stamp +"    " + $LogString
		
		If (!(Test-Path $this.LogFile)) {New-Item -Path $this.LogFile -Force}
		Add-content $this.LogFile -value $this.LogMessage

		switch -CaseSensitive -Wildcard ($LogString)
		{
			
			'*^*'
			{
				Write-Host "`n       " -NoNewline
				$LogString -split(" ") | foreach-object{ if($_ -ne '^'){Write-host $_" " -Fore Red -BackgroundColor White -nonewline}}
			}

			'*PASS*'
			{
				Write-Host "`n       " -NoNewline
				$LogString -split(" ") | foreach-object{ if($_ -eq 'PASSED'){Write-host $_" " -fore Green -nonewline} else{write-host $_" " -nonewline}}
				break
			}				
			
			'*warnings.*'
			{
				Write-Host "       " $LogString "`n        OPatch completed with Warnings, please check the Log file before proceeding."-Fore Yellow 
			}
			
			'*Checking*Folder*'
			{
				Write-Host "`n       " -NoNewline
				$LogString -split(" ") | foreach-object{ if($_ -eq 'FAILED'){Write-host $_" " -fore Red} else{write-host $_" " -nonewline}}
			}
			
			'*failed*'
			{
				Write-Host ""
				Write-Host "        " -NoNewline; Write-Host $LogString -Fore Red -BackgroundColor White
				Write-Host "        " -NoNewline; Write-Host "OPatch Failed, please check the Log file before proceeding." -Fore Red -BackgroundColor White
			}
			'*CAUTI*'
			{
				Write-Host ""
				Write-Host "        " -NoNewline; Write-Host $LogString -Fore Red -BackgroundColor White
				
			}
			'*RUNN*'
			{
				Write-Host "`n       " -NoNewline
				$LogString -split(" ") | foreach-object{ if($_ -eq 'RUNNING'){Write-host $_" " -fore Red -BackgroundColor White -nonewline} else{write-host $_" " -nonewline}}
			}
			'*STOP*'
			{
				Write-Host "`n       " -NoNewline
				$LogString -split(" ") | foreach-object{ if($_ -eq 'STOPPED'){Write-host $_" " -fore Green -nonewline} else{write-host $_" " -nonewline}}
			}	
			'*succ*'
			{
				if($LogString -like '*OPatch Version:*') 
				{
					Write-Host "       " $LogString -Fore Green
				}
				else 
				{
					Write-Host "`n      "$LogString -Fore Green 
					Write-Host "`n       Patch has been applied successfully."  -Fore Green 
					break
				}
			}
			'*(Y/N)*'
			{
				Write-Host "`n      "$LogString -Fore Yellow -NoNewline
			}
			'*~*'
			{
				Write-Host "`n       " -NoNewline
				$LogString -split(" ") | foreach-object{ if($_ -ne '~'){Write-host $_" " -Fore Yellow -nonewline}}
				break
			}

			'*[jJ]ava*'			# This will check for both java and Java
			{
				Write-Host "`n      "$LogString -Fore Yellow
			}

			default
			{
				Write-Host "      "$LogString
			}
			
		}

		return $LogString
	}

	[string] CheckServiceStatus($servicename)
	{
		$this.serivestatus = (Get-Service -name $servicename).status
		return $this.serivestatus
	}
	
	StopService($servicename)
	{	
		Stop-Service -Name $servicename
		$this.tmpservice = (Get-Service -Name $servicename).status
	
		while($this.tmpservice -ne 'Stopped')
		{
				Write-Host "`n       Waiting for the service to Stop. Current Status is : " $this.tmpservice
				Start-Sleep -seconds 3
				$this.tmpservice = (Get-Service -Name $servicename).status
		}
		
		$this.passvalue = "Service "+$servicename+"`t`t`t"+" STOPPED"
		$this.WriteLog($this.passvalue)
		
	}
	
	CheckFolderExists([string]$path)
	{
		if(Test-Path -Path $path)
		{
			$this.WriteLog("Checking if the Folder Exist `t`t`t`t`t`t`t PASSED `n")
		}				 
		else	
		{
			Write-Host ""
			$this.WriteLog("Checking if the Folder Exists`t`t`t`t`t`t`t FAILED `n`n")
		
			$this.passvalue = "The Folder " + $path + " Does not Exists. ~" 
			$this.WriteLog($this.passvalue)
			$this.WriteLog("Applying Patch Aborted.. ~ ") 
			
			switch -Wildcard ($path)
			{
				'*Tuxedo*' 		{$this.ShowTux() }
				'*opatch*'		{$this.ShowOpatch() }
				'*Weblogic*'	{$this.ShowWeblogic() }	
			}
			
		}
	}

    Print() {
        Write-Host $this.result -ForegroundColor Cyan
    }
	
	ShowTux() {
		 $this.WriteLog(" `n`n"												)
		 $this.WriteLog("----------------------------------------------"	)
		 $this.WriteLog("  T U X E D O  M A N A G E M E N T   M E N U "	    )
		 $this.WriteLog("----------------------------------------------`n"  )
		 $this.WriteLog("`n       1. Show Current Opatch Version"           )
		 $this.WriteLog("`n       2. Show Current Tuxedo Patch Level"       )
		 $this.WriteLog("`n       3. Apply Patch"                           )
		 $this.WriteLog("`n       4. Rollback Patch"                        )
		 $this.WriteLog("`n       5. Quit`n`n"                              )

		 
		 $this.val = Read-Host "       Enter your Choice here "
		 Write-Host "`n"
		 $this.passvalue = "`n       Entered Choice is : " + $this.val 
		 $this.WriteLog($this.passvalue)
		 
		 $this.result = switch($this.val)
		{
			1 { 
				Write-Host "`n"
				& $this.tuxpath $this.version | ForEach-Object { $this.WriteLog($_) }
                $this.ShowTux()
			}

			2 { 
				Write-Host "`n"
                & $this.tuxpath $this.lspatches | ForEach-Object { $this.WriteLog($_) }
                $this.ShowTux()
			}
			
            3 { 
				$env:OPATCH_PLATFORM_ID=233	
		
				Write-Host "`n       Please make sure to place the Patch.zip file under "  $this.tux_patch_path  " Folder"
				$this.choice = Read-Host "`n       Continue (Y / N ) ? "  
				
				
				if($this.choice -eq "Y") 
				{ 
				
					$this.CheckFolderExists($this.tux_patch_path)
				
					if(Get-ChildItem -Path $this.tux_patch_path -Filter *.zip) 
					{
						Write-Host "`n       Checking if the Patch File Exists" -NoNewline 
						Write-Host "                 PASSED" -Fore Green
						
					}
					else 
					{
						Write-Host "`n       Checking if the Patch File Exists" -NoNewline 
						Write-Host "                 FAILED" -Fore RED						
						Write-Host "`n       No Patch.zip file exists under " $this.tux_patch_path " Folder" -Fore Yellow
						Write-Host "`n       Applying Patch Aborted.." -Fore Yellow
						$this.ShowTux()
					}
					
					$this.expression = Get-ChildItem -Path $this.tux_patch_path -Filter *.zip
					Write-Host "`n       Patch found in Folder : "  -NoNewline
					Write-Host $this.expression -Fore Yellow -NoNewline
					Write-Host "              PASSED" -Fore Green
					Write-Host "`n`n       Is the Patch " -NoNewline; Write-Host $this.expression -Fore Yellow -NoNewline; Write-Host " correct ? (Y / N) : " -NoNewline
					$this.inchoice = Read-Host
					if(($this.inchoice -ne 'y') -or ($this.inchoice -ne 'Y')) 
					{ 
						Write-Host "`n       Applying Patch Aborted by the user."
						$this.ShowTux()	
					} 
					
					$this.WriteLog("`n       Verifying the status of Services...")
					Write-Host "`n"			

					$this.ser2 = $this.CheckServiceStatus("TListen 12.2.2.0.0_VS2017(Port: 3050)").ToUpper()	
					$this.passvalue = "`n       Service TListen 12.2.2.0.0_VS2017(Port: 3050)`t`t:	 "  + $this.ser2 
					$this.WriteLog($this.passvalue)

					$this.ser1 = $this.CheckServiceStatus("ORACLE ProcMGR V12.2.2.0.0_VS2017").ToUpper()
					$this.passvalue = "`n       Service ORACLE ProcMGR V12.2.2.0.0_VS2017`t`t:	 "  + $this.ser1 
					$this.WriteLog($this.passvalue)					

					$this.ser3 = $this.CheckServiceStatus("PeopleSoft*").ToUpper()	
					$this.passvalue = "`n       Service for Peoplesoft App Server and Process Scheduler`t:	 "  + $this.ser3 
					$this.WriteLog($this.passvalue)	
					
					if(($this.ser1 -eq 'RUNNING') -or ($this.ser2 -eq 'RUNNING') -or ($this.ser3 -eq 'RUNNING'))
					{	
						Write-Host "`n`n"
						$this.inchoice = Read-Host "`n`n       Some of the services are running. Do you want to Stop them ? (Y / N) "
						
						if($this.inchoice -eq "Y") 
						{
							$this.WriteLog("`n       Stopping the Services...`n")
							if($this.ser2 -eq 'RUNNING') { $this.StopService("TListen 12.2.2.0.0_VS2017(Port: 3050)") }
							$this.WriteLog("`n")
							if($this.ser1 -eq 'RUNNING') { $this.StopService("ORACLE ProcMGR V12.2.2.0.0_VS2017") } 
							$this.WriteLog("`n")
							if($this.ser3 -eq 'RUNNING') { $this.StopService("Service for Peoplesoft App Server and Process Scheduler") } 
							$this.WriteLog("`n")
							
							$this.ser1 = $this.CheckServiceStatus("ORACLE ProcMGR V12.2.2.0.0_VS2017").ToUpper()
							$this.ser2 = $this.CheckServiceStatus("TListen 12.2.2.0.0_VS2017(Port: 3050)").ToUpper()
							$this.ser3 = $this.CheckServiceStatus("PeopleSoft*").ToUpper()	
							
							if(($this.ser1 -ne 'RUNNING') -and ($this.ser2 -ne 'RUNNING') -and ($this.ser3 -ne 'RUNNING'))
							{
								$this.passvalue = "`n       Verifying the status of Services again....`t`t`t PASSED"
								$this.WriteLog($this.passvalue)
								$this.WriteLog("`n       Services are STOPPED, Proceeding with applying the Patch....")
								Start-Sleep -seconds 2
							}
							else 
							{
								Write-Host "`n       Some Services are still running." -Fore Yellow
								Write-Host "`n       Please abort the script and verify the status before continuing."      -Fore Yellow
							}
							
						}
					
						elseif($this.choice -eq "N") 
						{ 
							Write-Host "`n       Applying Patch Aborted by the user."
							$this.ShowTux()
						}
						
						else
						{ 
							Write-Host "`n       Invalid Value entered, please select again."
							$this.ShowTux()
						}
						
					}
					else 
					{
						Write-Host "`n"
						$this.WriteLog("`n       Services are STOPPED, Proceeding with applying the Patch....")
						Start-Sleep -seconds 2
					}
					
					$this.CallAnimate()
					
					$this.command = $this.tuxpath + " " + $this.patchapply + " " + $this.tux_patch_path + $this.expression + " -silent"
						
					Invoke-Expression -Command $this.command | ForEach-Object { $this.WriteLog($_) }
										
					#D:\Temp\TMP\pt\bea\tuxedo\OPatch\opatch.bat apply D:\temp\Patches\TuxedoPatch\$($this.expression) -silent | ForEach-Object { $this.WriteLog($_) }
					
					Write-Host "`n`n"
					
				}
				
				elseif($this.choice -eq "N") 
				{ 
					Write-Host "`n       Applying Patch Aborted by the user."
					$this.ShowTux()
				}
				
				else 
				{ Write-Host "`n       Incorrect option selected" }
					
			}
			
			4 {  
					Write-Host "`n    Rollback functionality not yet implemented." -Fore yellow
					Write-Host "    Please try again later."	-Fore yellow
					$this.ShowTux()
			 }
			
			5 { $this.ShowMenu() }
			
			default {
				Write-Host "`n    Incorrect option selected. Please select the correct Option.`n" 
				$this.ShowTux()
				
			}
		}
		 
	 }


	ShowWebLogic() {
		 Write-Host " `n`n"
		 Write-Host "--------------------------------------------------"	
		 Write-Host "  W E B L O G I C   M A N A G E M E N T   M E N U "	
		 Write-Host "-------------------------------------------------`n"
		 Write-Host "`n       1. Show Current Opatch Version"
		 Write-Host "`n       2. Show Current WebLogic PSU Level"
		 Write-Host "`n       3. Apply Patch"
		 Write-Host "`n       4. Rollback Patch"
		 Write-Host "`n       5. Quit`n`n"
		 $this.val = Read-Host "       Enter your Choice here "
		 
		 $this.result = switch($this.val)
		{
			1 { 
				Write-Host "`n"
				& $this.weblogicpath $this.version | ForEach-Object { $this.WriteLog($_) }
                $this.ShowWebLogic()
			   }

			2 { 
				Write-Host "`n"
				& $this.weblogicpath $this.lspatches | ForEach-Object { if($_ -like '*WLS PATCH SET UPDATE*'  ){$this.WriteLog($_) }}
                $this.ShowWebLogic()
			  }
			
            3 { 


				Write-Host "`n       Default Path for WebLogic PSU Zip is : " -nonewline
				Write-Host " \\<server.com>\temp\Software\PSU\WebLogic\Latest" -fore Yellow

				$this.temp = Read-Host "`n       Proceed with Default Path ? (Y/N)  "	
		
				if ($this.temp -eq 'n')
				{
					$this.val = Read-Host "`n       Please Enter the complete Path of the Folder Containgin WebLogic PSU Zip file  "
				}
				else 
				{
					$this.val = "\\<server.com>\temp\Software\PSU\WebLogic\Latest"	
				}

				Write-Host "`n       Looking for the latest WebLogic PSU Zip file in below Folder :"
				Write-Host "`n       " $this.val -fore Yellow -NoNewline

				if ( (get-childitem $this.val | Measure-object).count -ne 1)
				{
					Write-Host "`t`tFAILED" -fore Red -back White
					Write-Host "`n       CAUTION : The Folder has more than one item."
					Write-Host "`n       		  Please make sure that the folder only contains one latest PSU Zip File"
					$this.ShowWebLogic()
				}
				elseif ([System.IO.Path]::GetExtension((get-childitem $this.val).Name) -ne '.zip')
				{
					Write-Host "`t`tFAILED" -fore Red -back White
					Write-Host "`n       CAUTION : The Folder does not contain any .zip file"
					Write-Host "`n       		   Please make sure that the folder contains latest PSU Zip File"
					$this.ShowWebLogic()
				}
				else {
					Write-Host "		 PASSED" -fore Green
				}


				If (!(Test-Path $this.web_patch_path)) 
				{

					New-Item -Path $this.web_patch_path -ItemType "directory" -Force
					
				}

				$this.temp = $this.val + "\*"
				Copy-Item $this.temp -Destination $this.web_patch_path

				if(!($?))
				{
					Write-Host "`n       CAUTION : There were some issue while Copying the PSU Zip file."
					Write-Host "`n                 Please validate the copied ZIP file and continue again."
					$this.ShowWebLogic()
				}

				Write-Host "`n       Copying Zip File Status " -NoNewline
				Write-Host "`t`t`t`t`t`t`t`t PASSED" -Fore Green


				Write-Host "`n       Unzipping the PSU Zip file under the below Folder :"
				Write-Host "`n      " $this.web_patch_path -fore Yellow

				$this.val = (Get-ChildItem $this.web_patch_path).Name

				Set-Location $this.web_patch_path
			    jar.exe -xvf $this.val

				if(!($?))
				{
					Write-Host "`n       CAUTION : There were some issue while unzipping the PSU Zip file."
					Write-Host "`n                 Please validate the extracted files and continue again."
					$this.ShowWebLogic()
				}

				Write-Host "`n       Unzip Status " -NoNewline
				Write-Host "`t`t`t`t`t`t`t`t`t PASSED" -Fore Green

				Write-Host "`n       Removing the .zip file " -NoNewline

				del *.zip

				if(!($?))
				{
					Write-Host "`n       CAUTION : There were some issues while deleting the PSU Zip file."
					Write-Host "`n                 Please validate the files and continue again."
					$this.ShowWebLogic()
				}				

				else 
				{
					Write-Host "`t`t`t`t`t`t`t`t PASSED" -Fore Green
				}



				Write-Host "`n       Checking for Patch folder under" $this.web_patch_path "Folder"
						

				$this.CheckFolderExists($this.web_patch_path)
				
				if((Get-ChildItem -Path $this.web_patch_path -Name | Measure-Object).Count -ne 0) 
				{
					Write-Host "`n       Checking if the Patch File Exists" -NoNewline 
					Write-Host "`t`t`t`t`t`t PASSED" -Fore Green
				}
				else 
				{
					Write-Host "`n       Checking if the Patch File Exists" -NoNewline 
					Write-Host "                 FAILED" -Fore RED						
					Write-Host "`n       No file exists under" $this.web_patch_path " Folder" -Fore Yellow
					Write-Host "`n       Applying Patch Aborted.." -Fore Yellow
					$this.ShowWebLogic()
				}
				
					$this.expression = Get-ChildItem -Path $this.web_patch_path -Name
					Write-Host "`n       File found in Folder : "  -NoNewline
					Write-Host $this.expression -Fore Yellow -NoNewline
					Write-Host "`t`t`t`t`t`t`t PASSED" -Fore Green
					Write-Host "`n`n       Is the Patch Folder " -NoNewline; Write-Host $this.expression -Fore Yellow -NoNewline; Write-Host " correct ? (Y / N) : " -NoNewline
					$this.inchoice = Read-Host
					
					if(($this.inchoice -ne 'y') -or ($this.inchoice -ne 'Y')) 
					{ 
						Write-Host "`n       Applying Patch Aborted by the user."
						$this.ShowWebLogic()	
					} 
					
					
					Write-Host "`n       Verifying the status of Services.... `n"
					
					$this.ser1 = $this.CheckServiceStatus("*PIA*").ToUpper()	
					$this.passvalue = "PIA Service is "  + $this.ser1 
					$this.WriteLog($this.passvalue)					
					Write-Host "`n"
					
					if($this.ser1 -eq 'RUNNING')
					{
						
						$this.inchoice = Read-Host "`n       Some of the services are running. Do you want to Stop them ? (Y / N) "
						
						if($this.inchoice -eq "Y") 
						{
							$this.WriteLog("`n       Stopping the Services...")
							$this.StopService("*PIA*") 
							$this.WriteLog("`n")
							
							$this.ser1 = $this.CheckServiceStatus("*PIA*").ToUpper()	
							
							if($this.ser1 -ne 'RUNNING')
							{
								Write-Host "`n       Verifying the status of Services again .... " -NoNewline
								Write-Host "      PASSED" -Fore Green
								$this.WriteLog("`n       Services are STOPPED, Proceeding with applying the Patch....")
								Start-Sleep -seconds 2
							}
							else 
							{
								Write-Host "`n       Some Services are still running." -Fore Yellow
								Write-Host "`n       Please abort the script and verify the status before continuing."      -Fore Yellow
							}
							
						}
						else 
						{ 
							Write-Host "`n       Applying Patch Aborted by the user."
							$this.ShowWebLogic()	
						} 
						
					}	
					else 
					{
							$this.WriteLog("`n       Services are STOPPED, Proceeding with applying the Patch....")
							Start-Sleep -seconds 2
					}
						

					
			
				$this.CallAnimate() 
				
				#D:\Temp\TMP\pt\bea\OPatch\opatch.bat apply D:\temp\Patches\WebLogicPatch\$($this.expression) -silent | ForEach-Object { $this.WriteLog($_) }
				
				$this.command = $this.weblogicpath + " " + $this.patchapply + " " + $this.web_patch_path + "\"+ $this.expression + " -silent"
				
				Invoke-Expression -Command $this.command | ForEach-Object { $this.WriteLog($_) }
									
			}
			            
			4 { 
				Write-Host "`n    Rollback functionality not yet implemented." -Fore yellow
				Write-Host "    Please try again later."	-Fore yellow
				$this.ShowWebLogic()
			  }
			
			5 { $this.ShowMenu() }
			
			default {
				Write-Host "`n    Incorrect option selected. Please select the correct Option.`n" 
				$this.ShowWebLogic()
				}
		}
		 
	 }
	 
	 ShowOPatch() {
	
		 Write-Host " `n`n"
		 Write-Host "------------------------------------------------------------------"	
		 Write-Host "  W E B L O G I C   O P A T C H  M A N A G E M E N T   M E N U "	
		 Write-Host "------------------------------------------------------------------`n"
		 Write-Host "`n       1. Show Current WebLogic Opatch Version"
		 Write-Host "`n       2. Upgrade WebLogic Opatch"
		 Write-Host "`n       3. Quit"
		 
		 $this.val = Read-Host "`n       Enter your Choice here "
		 
		 $this.result = switch($this.val)
		{
			1 { 
				Write-Host "`n"
				& $this.weblogicpath $this.version | ForEach-Object { $this.WriteLog($_) }
                $this.ShowOPatch()
			   }

			2 { 
				Write-Host "`n"
				Write-Host "`n       Please make sure to Unzip the Patch.zip file under " $this.opatch_patch_path " Folder"
				
				$this.choice = Read-Host "`n       Continue (Y / N ) ? "   
				
				if($this.choice -eq "Y") 
				{
					$this.CheckFolderExists($this.opatch_patch_path)
					
					if((Get-ChildItem -Path $this.opatch_patch_path -Name | Measure-Object).Count -ne 0) 
					{
						
						Write-Host "`n       Checking if the Patch File Exists" -NoNewline 
						Write-Host "                 PASSED" -Fore Green
						
					}
					else 
					{
						Write-Host "`n       Checking if the Patch File Exists" -NoNewline 
						Write-Host "                 FAILED" -Fore RED						
						Write-Host "`n       No file exists under" $this.opatch_patch_path "Folder" -Fore Yellow
						Write-Host "`n       Applying Patch Aborted.." -Fore Yellow
						$this.ShowOPatch()
					}
					
					
					$this.expression = Get-ChildItem -Path $this.opatch_patch_path -Name
					Write-Host "`n       File found in Folder : "  -NoNewline
					Write-Host $this.expression -Fore Yellow -NoNewline
					Write-Host "                    PASSED" -Fore Green
					Write-Host "`n`n       Is the Patch Folder " -NoNewline; Write-Host $this.expression -Fore Yellow -NoNewline; Write-Host " correct ? (Y / N) : " -NoNewline
					
					$this.inchoice = Read-Host
					if(($this.inchoice -ne 'y') -or ($this.inchoice -ne 'Y')) 
					{ 
						Write-Host "`n       Applying Patch Aborted by the user."
						$this.ShowOPatch()	
					} 
					

				Write-Host "`n       Please Make sure that all the process using WebLogic are stopped before proceeding."
				$this.choice = Read-Host "`n       Continue (Y / N ) ? " 
				if($this.choice -ne "Y" -or $this.choice -ne "y") 
				{
					Write-Host "`n       Applying Patch Aborted by the user."
					$this.ShowOPatch()
				}

				$this.ser1 = $this.CheckServiceStatus("*PIA*").ToUpper()	
				$this.passvalue = "`n       PIA Service is "  + $this.ser1 
				$this.WriteLog($this.passvalue)					
					
				if($this.ser1 -eq 'RUNNING')
				{
						$this.inchoice = Read-Host "`n       Some of the services are running. Do you want to Stop them ? (Y / N) "
						
						if($this.inchoice -eq "Y") 
						{
							$this.WriteLog("`n       Stopping the Services...")
							$this.StopService("*PIA*") 
							$this.WriteLog("`n")
							
							$this.ser1 = $this.CheckServiceStatus("*PIA*").ToUpper()	
							
							if($this.ser1 -ne 'RUNNING')
							{
								Write-Host "`n       Verifying the status of Services again .... " -NoNewline
								Write-Host "      PASSED" -Fore Green
								$this.WriteLog("`n       Services are STOPPED, Proceeding with applying the Patch....")
								Start-Sleep -seconds 2
							}
							else 
							{
								Write-Host "`n       Some Services are still running." -Fore Yellow
								Write-Host "`n       Please abort the script and verify the status before continuing."      -Fore Yellow
							}
							
						}
				} 
				else 
				{
					$this.WriteLog("`n       Services are STOPPED, Proceeding with applying the Patch....")
					Start-Sleep -seconds 2
				}
				
					Write-Host "`n       Proceeding to update WebLogic OPatch.... `n"
					
					$this.command = $this.javahome + " -jar " + $this.opatch_patch_path  + $this.expression + "\opatch_generic.jar -silent oracle_home=" + $this.weblogichome
					
					#java -jar <PATCH_HOME>\6880880\opatch_generic.jar -silent oracle_home=<ORACLE_HOME_LOCATION>
					
					$this.prev_ver = (& $this.weblogicpath $this.version) | Select-Object -First 1

					$this.CallAnimate()

					Invoke-Expression -Command $this.command | ForEach-Object { $this.WriteLog($_) }
					$this.new_ver = (& $this.weblogicpath $this.version) | Select-Object -First 1
					Write-Host "`n "
					Write-Host "`n       Previous OPatchVersion :" $this.prev_ver
					Write-Host "`n       New OPatchVersion :     " $this.new_ver
					
					
				}
			
				
				elseif($this.choice -eq "N") 
				{ 
					Write-Host "`n       Applying Patch Aborted by the user."
					$this.ShowOPatch()
				}
				
				else 
				{ 
					Write-Host "`n       Incorrect option selected!" 
					$this.ShowOPatch()
				}
				
                $this.ShowOPatch()
			}
			
			3 { $this.ShowMenu() }
			
			default {
				Write-Host "`n    Incorrect option selected. Please select the correct Option.`n" 
				$this.ShowWebLogic()
			}
		}
	
	 }
	 
    ShowJava() 
	{
		 $this.WriteLog(" `n`n"												)
		 $this.WriteLog("----------------------------------------------"	)
		 $this.WriteLog("   J A V A   M A N A G E M E N T   M E N U "	    )
		 $this.WriteLog("----------------------------------------------`n"  )
		 $this.WriteLog("`n       1. Show Current JDK Version"           )
		 $this.WriteLog("`n       2. Upgrade JDK "       )
		 $this.WriteLog("`n       3. Quit`n`n"                           )

		 $this.val = Read-Host "       Enter your Choice here "
		 Write-Host "`n"
		 $this.passvalue = "`n       Entered Choice is : " + $this.val 
		 $this.WriteLog($this.passvalue)

		# In Powershell, Whenver we are calling a Class MEthod for any reason, it will get executed.
		# For Ex : $Test = $this.CheckJDK()
		# This will not only put the return value in $Test, but also run the method CheckJDK()
		# Hence, in our below logic, if we simply use CheckJDK90 it will be run every time
		# When when we are validating the return value in IF, it will still get executed
		# Because of this we will have unwanted values in the output, when we do not want anyting to be printed on screen (While jsut checking if the JDK is not present)
		# BUt at the same time, there is a scenario when we want the output to be printed on the screen (Checking the Version and dispalying)
		# TO counter this, we have made the method CHeckJDK() to accept some arguements
		# When we do not want any thing to be printed on the screen, we will pass 0. HEre it will simply check if jdk os present or not and retirn True False
		# When we actualy want to display on the screen, we will pass 1. 

		 $this.result = switch($this.val) {

			 1 {
					# JDK Version
					$this.CheckJDK(1)
			   }

			 2 {
				#Step 1: Check if Java is Installed 
				
				if (!$this.CheckJDK(0))  # JDK is not Installed
				{
					Write-host "`n"
					$this.WriteLog("Please confirm JDK Installation before proceeding~")
					$this.temp = $this.WriteLog("Would you like to proceed with JDK Installation ? (Y/N) : ")
					$this.val = Read-Host 
					Write-host "`n"
					
					if($this.val -eq 'Y') 
					{
						$this.JdkInstPath = $this.InstallJDK()
					}
					elseif($this.val -eq 'N') 
					{
						$this.WriteLog("You have chosen not  to proceed with the JDK installation !!")	
						$this.ShowJava()
					}	
									
				}
				else { 			# JDK is Installed
					$this.CheckJDK(1)			# We are Passing 1, since we  want output on the screen
					
					Write-Host "`n"
					$this.WriteLog("Proceeding to Upgrade JDK..")

					# Repeating Code from Applying Weblogic PSU to check PIA Service is up or not
					# Ideally the servce should be stopped

					Write-Host "`n       Verifying the status of Services.... `n"
					
					$this.ser1 = $this.CheckServiceStatus("*PIA*").ToUpper()	
					$this.passvalue = "PIA Service is "  + $this.ser1 
					$this.WriteLog($this.passvalue)					
					Write-Host "`n"
					
					if($this.ser1 -eq 'RUNNING')
					{
						
						$this.inchoice = Read-Host "`n       PIA services are running. Do you want to Stop them ? (Y / N) "
						
						if($this.inchoice -eq "Y") 
						{
							$this.WriteLog("`n       Stopping the Services...")
							$this.StopService("*PIA*") 
							$this.WriteLog("`n")
							
							$this.ser1 = $this.CheckServiceStatus("*PIA*").ToUpper()	
							
							if($this.ser1 -ne 'RUNNING')
							{
								Write-Host "`n       Verifying the status of Services again .... " -NoNewline
								Write-Host "      PASSED" -Fore Green
								$this.WriteLog("`n       Services are STOPPED, Proceeding with JDK Installation...")
								Start-Sleep -seconds 2
							}
							else 
							{
								Write-Host "`n       Some Services are still running." -Fore Yellow
								Write-Host "`n       PLease make sure to stop the service, before Re - Installing it."      -Fore Yellow
							}
							
						}
						else 
						{ 
							Write-Host "`n       It is highly recommended to stop the PIA Service before proceeding with JDK Install." -Fore Yellow
							Write-Host "`n       You have chosen not to stop the service." -Fore Yellow
							Write-Host "`n       PLease make sure to stop the service, before Re - Installing it." -Fore Yellow
						} 
						
					}	
					else 
					{
							$this.WriteLog("`n       Services are STOPPED, Proceeding with JDK Installation...`n`n")
							Start-Sleep -seconds 2
					}

					
					$this.JdkInstPath = $this.InstallJDK()
					Write-host "`n"
					$this.WriteLog("Post JDK Upgrade, the WebLogic Configuration File need to updated with the new JAVA_HOME")
					$this.WriteLog("Would you like to proceed with Configuration ? (Y/N) : ")
					$this.val = Read-Host 
					Write-host "`n"

					if ($this.val -eq 'Y')
					{
						Write-Host "`n       Configuring new JDK in Weblogic .globalEnv.properties"   -Fore Yellow
						$this.temp = Get-Content D:\Apps\bea\weblogic\oui\.globalEnv.properties | Where-Object {$_ -like 'JAVA_HOME=*'} 
						$this.temp = $this.temp.replace('\:',':').replace('\\','\')
						$this.temp = $this.temp | foreach {  $_.split("=")[1] }
						Write-host "`n       Current JAVA_HOME                           : "  $this.temp 

						Write-host "`n       Backing Up JAVA_HOME into OLD_JAVA_HOME     : " -NoNewline
						$this.val = (cmd /c D:\Apps\bea\weblogic\oui\bin\setProperty.cmd -name OLD_JAVA_HOME -value D:\Apps\bea\jdk1.8.0_321) | Out-String
					
						if ($this.val -Match "successfull")
						{
							Write-host " [PASSED]" -fore Green
						}	
						else 
						{
							Write-host " [FAILED]" -fore Red
							Write-host "`n       setProperty Command failed. Please set the OLD_JAVA_HOME manually and continue."
						}			


						$this.temp = Get-Content D:\Apps\bea\weblogic\oui\.globalEnv.properties | Where-Object {$_ -like 'OLD_JAVA_HOME=*'}
						$this.temp = $this.temp.replace('\:',':').replace('\\','\')
						$this.temp = $this.temp | foreach {  $_.split("=")[1] }
						Write-host "`n       Backed up JAVA_HOME value in OLD_JAVA_HOME  : "  $this.temp
				
						Write-host "`n       Configuring new JAVA_HOME                   : " -NoNewline
						$this.val = (cmd /c D:\Apps\bea\weblogic\oui\bin\setProperty.cmd -name JAVA_HOME -value D:\Apps\bea\jdk1.8.0_331) | Out-String
						
						if ($this.val -Match "successfull")
						{
							Write-host " [PASSED]" -fore Green
						}	
						else 
						{
							Write-host " [FAILED]" -fore Red
							Write-host "`n       setProperty Command failed. Please set the OLD_JAVA_HOME manually and continue."
						}
				
						$this.temp = Get-Content D:\Apps\bea\weblogic\oui\.globalEnv.properties | Where-Object {$_ -like 'JAVA_HOME=*'}		
						$this.temp = $this.temp.replace('\:',':').replace('\\','\')
						$this.temp = $this.temp | foreach {  $_.split("=")[1] }
						Write-host "`n       New JAVA_HOME                               : "  $this.temp

						Write-Host "`n"
						$this.temp = Read-host "`n       Do you wish to Re - Install the PIA Service Now ? (Y/N) " 

						if ($this.temp -ne 'y')
						{
							Write-Host "`n       PIA Service Re-installation aborted by the user." -fore Yellow
							Write-Host "`n       Please make sure to Re-install the PIA service in order to reflect the new JDK "  -fore Yellow
							Write-Host "`n`n"
							$this.ShowJava()
						}

						$this.temp = Read-host "`n       Please Enter the complete Webserver Domain folder path  "

						Write-host "`n       Removing the PIA Service                    : " -NoNewline
			
						$this.val = $this.temp + "\bin\uninstallNTServicePIA.cmd"
						$this.val = $this.val | cmd | Out-String
			
						
						if ($this.val -Match "PIA removed.")
						{
								Write-host " [PASSED]" -fore Green
						}	
						else 
						{
							Write-host " [FAILED]" -fore Red
							Write-host "`n       Removal of PIA Service failed. PLease try to Re-install the service manually"
							$this.ShowJava()
						}
						
						Write-host "`n       Installing the PIA Service                  : " -NoNewline
						$this.val = $this.temp + "\bin\installNTServicePIA.cmd"
						$this.val = $this.val | cmd | Out-String
						
						if ($this.val -Match "PIA installed.")
						{
								Write-host " [PASSED]" -fore Green
						}	
						else 
						{
							Write-host " [FAILED]" -fore Red
							Write-host "`n       Installing PIA Service failed. PLease try to Re-install the service manually"
							$this.ShowJava()
						}

						Write-host "`n       PIA Service Installed Successfully" -fore Green
						Write-host "`n       Please Change the Log On Settings in Service and start the Service" -fore Yellow

						$this.val = Read-Host "`n       Do you want to set JAVA_HOME Environment Variable to new JDK Home ? (Y/N) "
						
						if($this.val -ne 'y')
						{
							Write-Host "`n       JAVA_HOME not set to new JDK Home. PLease set it manually."
						}

						[Environment]::SetEnvironmentVariable("JAVA_HOME", $this.JdkInstPath, [System.EnvironmentVariableTarget]::Machine)

						Write-Host "`n       JAVA_HOME set to new JDK Home.`n`n"

					}
					else
					{
						$this.WriteLog("WebLogic Configuration Update Aborted."+ " ~")
						$this.WriteLog("Please Update manually if required."+ " ~")	
					}

					$this.ShowJava()

					#Take path of new installables from the user and pass it to InstallJDK MEthod
				}





			 }

			 3 {
				 
				$this.ShowMenu() 
				  
				  }
			 
			 default {}
		 }
	
	}
   
   
    [Outcome] Eval() {
		
        return [Outcome]::Continue
    }
	 
	[Outcome] ShowMenu() {
		$this.ShowLogo()
		$this.WriteLog("`n`n")
		$this.WriteLog("Please choose from below Options : 		")
		$this.WriteLog("                                     		")		
		$this.WriteLog("`n       1. Tuxedo                          ")
		$this.WriteLog("`n       2. WebLogic                        ")
		$this.WriteLog("`n       3. OPatch ")
		$this.WriteLog("`n       4. JAVA ")
		$this.WriteLog("`n       5. Quit `n`n ")

		$this.val = Read-Host "        Enter your Choice here "
		$this.passvalue = "`n        Entered Choice is : " + $this.val 
		$this.WriteLog($this.passvalue)
		
		$this.result = switch($this.val)
		{
			1 { $this.ShowTux() }
			2 { $this.ShowWebLogic() }
			3 { $this.ShowOPatch() }
			4 { $this.ShowJava() }
			5 { return [Outcome]::Quit }
			default {
				$this.result = "`n        Incorrect choice selected"
				Write-Host "    Incorrect option selected. Please select the correct Option.`n" 
				return [Outcome]::Continue
				}
		}
		
		return [Outcome]::Continue
		
	 }
	
 }
 
 
 $obj = New-Object Opatch_Manager
 $obj.REPL()
 
 	 
#END-SCRIPT
