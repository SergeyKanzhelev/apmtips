C:\src\mseng\yari\rubyinstaller.ps1 2.0.0
$env:path = $env:path + ";C:\Python27"
$env:path = $env:path + ";C:\tools\which2.20\bin"
cd C:\src\github\apmtips
& 'C:\Program Files\IIS Express\iisexpress.exe' /path:c:\src\github\apmtips\public /port:1211