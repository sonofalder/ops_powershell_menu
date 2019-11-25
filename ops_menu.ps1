$findFilesFoldersOutput = "$env:USERPROFILE\Documents\findLargeFolders.txt";
$outputWidth = 150;


###################################
# Elevate Privileges
###################################

Write-Host "Attempting to run as Admin..."
# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   #$Host.UI.RawUI.BackgroundColor = "Black"
   #$Host.UI.RawUI.ForegroundColor = "Green"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   # Exit from the current, unelevated, process
   #exit
   }

###################################
# Check / Kick logged in Users
###################################
function loggedIN {
echo ""
echo "                  Currently Logged in Users"
echo "                  ========================="
echo ""
#command to get logged in sessions and session ID
qwinsta /server:$hostname
echo ""
#Variable to store answer on whether or not user wants to kill logged in ID 
$logged = read-host "Enter the ID of the user you want to kick -or- Enter (N) to exit to the Main Menu"
#switch case to handle answer 
switch ($logged) {
  #if answer is "N" exit to main menu 
    "N" {mainmenu}
    #Otherwise print the kill ID command 
    default {
    echo ""
    #echo command to kill ID, do not offer the option to run this for the user 
    echo "In order to kill this session open new terminal and enter the following command`
    

                                rwinsta $logged /server:$hostname`

    "
    read-host "                  Press any key to continue to main menu"
    mainmenu}
    }
    #run the loggedIN function
    loggedIN
  }

###################################
# Scan Folders in Custom Drive
###################################
Function customScan {
  #Remove stale output file
#set-location "\\$hostname\"
Write-Host " "
write-host "Type a Drive Letter You Want to Scan:"
$currentServer = "\\$hostname\"
$customDrive = Read-Host 'Ex: C$\'
write-host "What directory path would you like to scan for on that drive?"
write-host "Ex: Windows\"
$customPath = Read-Host 
$customLocation= $currentServer + $customDrive + $customPath
$subDirectories = Get-ChildItem -force -Path "$customLocation" | Where-Object{($_.PSIsContainer)} | foreach-object{$_.Name}
Write-Host " "
Write-Host "Calculating folder sizes for $customLocation,"
Write-Host "this process will take a few minutes..."
" "  | out-file -width $outputWidth $findFilesFoldersOutput -append
"Estimated folder sizes for $customLocation :" | out-file -width $outputWidth $findFilesFoldersOutput -append
Write-Host " "
" "  | out-file -width $outputWidth $findFilesFoldersOutput -append
$folderOutput = @{}
foreach ($i in $subDirectories)
  {
  $targetDir = "$customLocation" + $i
  $folderSize = (Get-ChildItem -Path $targetDir -Recurse -force | Measure-Object -Property Length -Sum).Sum 2> $null
  $folderSizeComplete = "{0:N0}" -f ($folderSize / 1KB) + "KB" 
  $folderOutput.Add("$targetDir" , "$folderSizeComplete")
    write-host " Calculating $targetDir..."
}
$folderOutput.GetEnumerator() | sort-Object Value | format-table -wrap -autosize | out-file -width $outputWidth $findFilesFoldersOutput -append
Write-Host " "
Write-Host "Attempting to open scan results with notepad..."
c:\windows\system32\notepad.exe "$findFilesFoldersOutput"
Write-Host " "
Write-Host "Scan saved to: $findFilesFoldersOutput..."
Write-Host " "
$conResp = Read-Host "Did you want to scan another directory (y/n)?"
if ($conResp -eq "y") {
    customScan
}
elseif ($conResp -eq "n") {
    Remove-Item $findFilesFoldersOutput 2> $null
    mainmenu
}
}
  

###################################
# Check Last 20 Events Logs 
###################################
function EventLogs {
#Read user entry for the type of log they want to look at and store it in the value $typeEvent
$typeEvent = read-host "`

Select an event type:`

1. Check for Error Events`
2. Check for Warning Events`
3. Check for  Informational Events`


Enter a desired value: "

# import value based on customer selection into $typeEvent variable
switch ($typeEvent) {
  1{$typeEvent = "Error"}
  2{$typeEvent = "Warning"}
  3{$typeEvent = "Information"}
}
# $optionEvent value meant for selecting the type of logs user wants to view
$optionEvent = read-host "`

Select an event option:`

1. Check System $typeEvent`
2. Check Application $typeEvent`


Enter a desired value: "
  #switch case for what to store in the $optionEvent variable 
  switch ($optionEvent) {
  1{$optionEvent = "System"}
  2{$optionEvent = "Application"}
}
# Import variables selected into the Get-Event command 
$EventsLogs = Get-EventLog $optionEvent -EntryType $typeEvent -newest 20 -Computer $hostname | Format-List
$EventsLogs | Out-file "$env:USERPROFILE\Documents\EventsLog.txt"
#Reads the content of the calue stored in the file and prints it to the console
Get-Content "$env:USERPROFILE\Documents\EventsLog.txt"
echo ""
#Wait for customer to press a key before returning to the main menu 
read-host "                  Press any key to continue to main menu"
mainmenu
}
###########################################
# Uptime for user and System and unexpected
###########################################
function userUP {
  echo ""
  echo "Uptime for $hostname"
  echo "===================="
  echo ""
  # function to show the system uptime
  function actualUptime {
    echo "Last Reboot"
    echo "==========="
    echo ""
    #atores the value of the system uptime in $actualUptime
    $actualUptime = Get-WmiObject win32_operatingsystem -ComputerName $hostname | select csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
    #Send the output of $actualUptime to a file in the users Documents directory
    $actualUptime | Out-file "$env:USERPROFILE\Documents\uptime.txt"
    #Reads the content of the calue stored in the file and prints it to the console
    Get-Content "$env:USERPROFILE\Documents\uptime.txt"
    echo ""
}
# run the actualUptime function 
actualUptime
 echo "Last User Reboot"
 echo "================"
 echo ""
# variable $upuser to store the value of the last 5 user reboots 
$upuser = gwmi win32_ntlogevent -ComputerName $hostname -Filter "LogFile='System' and EventCode='1074' and Message like '%restart%'" | select User,@{n="Time";e={$_.ConvertToDateTime($_.TimeGenerated)}} | select -first 5
# sends the output of the command ot a file 
$upuser |  Out-file "$env:USERPROFILE\Documents\upuser.txt"
# takes the content placed in the file and reads it 
Get-Content "$env:USERPROFILE\Documents\upuser.txt"
echo ""
# allows user to press enter before exiting to main menu 
read-host "                  Press any key to continue to main menu"

  mainmenu
}  
###########################################
# Confirms if you actually want to exit 
###########################################  
function areyousure {$areyousure = read-host "Are you sure you want to exit? (y/n)"  
           if ($areyousure -eq "y"){exit}  
           if ($areyousure -eq "n"){mainmenu}  
           else {write-host -foregroundcolor red "Invalid Selection"   
                 areyousure 
                 mainmenu 
                }  
}

###########################################
# Gets all comp info and drive info 
###########################################  
function compInfo {
function GetComputerInfo {
      
        # ComputerSystem info
        $CompInfo = Get-WmiObject Win32_ComputerSystem -comp $hostname

        # OS info
        $OSInfo = Get-WmiObject Win32_OperatingSystem -comp $hostname

        # Serial No
        $BiosInfo = Get-WmiObject Win32_BIOS -comp $hostname

        # CPU Info
        $CPUInfo = Get-WmiObject Win32_Processor -comp $hostname

        # Create custom Object for Hostname, Domain, Model, Serial Number, and RAM
        $myobj = "" | Select-Object Name,Domain,Model,MachineSN,OS,ServicePack,WindowsSN,Uptime,RAM,Disk
        $myobj.Name = $CompInfo.Name
        $myobj.Domain = $CompInfo.Domain
        $myobj.Model = $CompInfo.Model
        $myobj.MachineSN = $BiosInfo.SerialNumber
        $myobj.OS = $OSInfo.Caption
        $myobj.ServicePack = $OSInfo.servicepackmajorversion
        $myobj.WindowsSN = $OSInfo.SerialNumber
        $myobj.uptime = (Get-Date) - [System.DateTime]::ParseExact($OSInfo.LastBootUpTime.Split(".")[0],'yyyyMMddHHmmss',$null)
        $myobj.uptime = "$($myobj.uptime.Days) days, $($myobj.uptime.Hours) hours," +`
          " $($myobj.uptime.Minutes) minutes, $($myobj.uptime.Seconds) seconds" 

        $myobj.RAM = "{0:n2} GB" -f ($CompInfo.TotalPhysicalMemory/1gb)
        $myobj.Disk = GetDriveInfo $hostname

        #Return Custom Object"
        $myobj

}

###########################################
# Gets all Drive info 
########################################### 
function GetDriveInfo {
    # Get disk sizes
    $logicalDisk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $hostname
    foreach($disk in $logicalDisk)
    {
        $diskObj = "" | Select-Object Disk,Size,FreeSpace,FreePerc
        $diskObj.Disk = $disk.DeviceID
        $diskObj.Size = "{0:n0} GB" -f (($disk | Measure-Object -Property Size -Sum).sum/1gb)
        $diskObj.FreeSpace = "{0:n0} GB" -f (($disk | Measure-Object -Property FreeSpace -Sum).sum/1gb)
        $diskObj.FreePerc = "{0:P2}" -f ($disk.FreeSpace / $disk.Size)
        $text = "{0} Capacity: {1}  Avaiable Space: {2} - {3}" -f $diskObj.Disk,$diskObj.size,$diskObj.Freespace,$diskObj.FreePerc
        $msg += $text  + [char]13 + [char]10
    }
    $msg
}

GetComputerInfo 2> $null | Out-file "$env:USERPROFILE\Documents\compinfo.txt"
Get-Content "$env:USERPROFILE\Documents\compinfo.txt"
read-host "                  Press any key to continue to main menu"
mainmenu
}

###########################################
# Check services status 
########################################### 
function GetServiceStatus {
echo ""
$svcname = read-host "                  Please Enter A service Name"
echo ""
echo "Checking Service Status"
echo "======================="
echo ""
$svcstatus = get-service -name $svcname -ComputerName $hostname
$svcstatus
echo ""
echo "  Would you like to :`
  
  1. START the $($svcname.toString().toUpper()) process(es)`
  2. STOP the $($svcname.toString().toUpper()) process(es)`
  3. ENTER a NEW servicename`
  4. Exit to Main Menu`
"

$SvcAnswer = read-host "                  Please select the numbered option: "
echo ""
if ($SvcAnswer -eq 1) {echo ""
echo ""
echo "                  Starting $svcname . . ."
echo ""
get-service -name $svcname -ComputerName $hostname | Start-Service -Verbose
echo ""
get-service -name $svcname -ComputerName $hostname
echo ""
read-host "                  Press any key to continue to main menu"
mainmenu
}
echo ""
if ($SvcAnswer -eq 2) {echo ""
echo "                  Stopping $svcname . . ."
echo ""
get-service -name $svcname -ComputerName $hostname | Stop-Service -Verbose
echo ""
get-service -name $svcname -ComputerName $hostname
echo ""
read-host "                  Press any key to continue to main menu"
mainmenu}
if ($SvcAnswer -eq 3) {GetServiceStatus}
if ($SvcAnswer -eq 4) {mainmenu}
 }

###########################################
# Gets CPU counter Info  
########################################### 
 function checkCPU {
 echo ""
 echo "CPU for $hostname"
 echo "================="
 echo ""
 function procInfo {
  $procInfo = Get-WmiObject -class Win32_processor -ComputerName $hostname -ErrorAction SilentlyContinue | Select-Object -Property systemname,NumberOfCores,NumberOfLogicalProcessors | ft -AutoSize
  ($procInfo 2> $null) | Out-file "$env:USERPROFILE\Documents\procinfo.txt"
  Get-Content "$env:USERPROFILE\Documents\procinfo.txt"
 }

 procInfo
 function chckCPU {
$processes = 0
$processes = Get-Counter -ComputerName $hostname '\Process(*)\% Processor Time' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty countersamples | Select-Object -Property instancename, cookedvalue | Sort-Object -Property cookedvalue -Descending | Select-Object -First 15 | ft InstanceName,@{L='CPU';E={($_.Cookedvalue/100).toString('P')}} -AutoSize
($processes 2> $null) | Out-file "$env:USERPROFILE\Documents\cpu.txt"
Get-Content "$env:USERPROFILE\Documents\cpu.txt"
}
chckCPU
echo ""
  $CPUanswer = read-host "                  1. Refresh `
                  2. Return to Main Menu`

                  Select a numbered option: "

  if ($CPUanswer -eq 1) {checkCPU}
  else {mainmenu}
}  

###########################################
# Get and Kill Processes
########################################### 
 function ServicesPID {tasklist /svc /s $hostname
  echo ""
  echo ""
  echo "==============================================================================="
  echo ""
  $killPID = read-host "Enter a PID if you would like to see the command to force kill a process, `
otherwise enter the letter ""N"" to exit to the mainmenu"
  echo ""
  if ($killPID -eq "N") {
      mainmenu
  }
  else {
    clear
    echo ""
    echo " Enter the following command in a new PowerShell window to kill the PID you selected"
    echo ""
    write-host "                  taskkill /s $hostname /PID $killPID"
    echo ""
      
  }
  read-host "                  Press any key to continue to main menu"
  mainmenu
}

###########################################
# Pings machine before continuing 
###########################################
  function PingMachine {
   $hostname = [string]$hostname
   $pingresult = Get-WmiObject win32_pingstatus -f "address='$hostname'"
   if($pingresult.statuscode -eq 0) { $true } else {$false}
    }

function RemoteSession {
  echo ""
  $confrim = read-host "Connection to $hostname as admin (Y)          Connect to $hostname as user (N)`
(Y/N)?"
echo ""
  if ($confirm -eq "N") {mstsc /v:$hostname
      read-host "                  Press any key to continue to main menu"   
      mainmenu  
  }

  else {mstsc /v:$hostname /admin
      read-host "                  Press any key to continue to main menu"   
      mainmenu
  
  }   
}

###########################################
# Get the hostname of the server 
###########################################
function hostINFO {
  echo ""
  $hostname = read-host "                  Please enter a desired hostname"
  echo ""
  $online=PingMachine $hostname
  if ($online -eq $true) {
      mainmenu
  }
  else {
              # Ping Failed!
        Write-Host "Error: $hostname not Pingable" -fore RED
        $answer = read-host "Do you still want to send remote commands to $hostname (Y/N)?"
        if ($answer -eq "Y") {
            mainmenu
        }
        else {
            hostINFO
        }
  }

}

 #Mainmenu function. Contains the screen output for the menu and waits for and handles user input.  

 function mainmenu {
 $shellfile = split-path $MyInvocation.PSCommandPath -Leaf 
 cls
 echo ""
 echo ""  
 echo "               "
 echo "               ============================================="
 echo "               >                                           <"  
 echo "               >       Type `"Exit`" to quit                 <"
 echo "               >                                           <"
 echo "               >       Type `"New`" for new SERVER           <"
 echo "               >                                           <"
 echo "               ============================================="
 echo "               >                                           <"
 echo "               >       1. List/Kill Running Tasks          <"
 echo "               >                                           <" 
 echo "               >       2. Check CPU                        <"
 echo "               >                                           <" 
 echo "               >       3. Comp/Disk Space Info             <"
 echo "               >                                           <"
 echo "               >       4. Start/Stop Services              <"
 echo "               >                                           <"
 echo "               >       5. RDP                              <"
 echo "               >                                           <"
 echo "               >       6. Event Logs (20 newest)           <"
 echo "               >                                           <" 
 echo "               >       7. Uptime & User Reboots            <"
 echo "               >                                           <"
 echo "               >       8. Check/Kick logged in Users       <"
 echo "               >                                           <"
 echo "               >       9. Scan Directory Size              <"
 echo "               >                                           <"     
 echo "               =============================================" 
 echo ""
 echo "               SERVER      ========>>   $hostname       " 
 echo "               EXECUTING   ========>>   $shellfile             "
  foreach ($num in 1,2,3,4,5){
   echo ""
 }
 $answer = read-host "                  Please Make a Number Selection"  
 if ($answer -eq 1){ServicesPID}  
 if ($answer -eq 2){checkCPU}
 if ($answer -eq 3) {compInfo} 
 if ($answer -eq 4) {GetServiceStatus}
 if ($answer -eq 5) {RemoteSession}
 if ($answer -eq 6) {EventLogs}
 if ($answer -eq 7) {userUP}
 if ($answer -eq 8) {loggedIN}
 if ($answer -eq 9) {customScan}
 if ($answer -eq "Exit") {areyousure}
 if ($answer -eq "New") {hostINFO}
 else {write-host -ForegroundColor red "Invalid Selection"  
       sleep 5  
       mainmenu
      }
}

hostINFO
