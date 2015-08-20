---
layout: post
title: "powershell to process all IIS applications"
date: 2015-08-20 07:45:49 -0700
comments: true
categories:
- configuration
- troubleshooting
- MMA 
---
In the lights of shutting down of Appliciton Insights in Visaul Studio Online portal for the full transition to the new Azure portal here is a script I used  

Change powershell to disable context initializer.

``` powershell
Function DisableMemoryCollection($path)
{
    $strFileName = "$path\\ApplicationInsights.config"

    Write-Host "Looking for ApplicationInsights.config in $path"

    If (Test-Path $strFileName){
      Write-Host "  File exists - making a copy at $strFileName.old"
      Copy-Item -Path $strFileName -Destination "$strFileName.old"

      $xml = [xml](Get-Content $strFileName)
      $nsmgr = New-Object System.XML.XmlNamespaceManager($xml.NameTable)
      $nsmgr.AddNamespace('ai','http://schemas.microsoft.com/ApplicationInsights/2013/Settings')

      $memorySettingsNodes = $xml.SelectNodes("//ai:MemoryEventSettings", $nsmgr)

      foreach($node in $memorySettingsNodes)
      {
        Write-Host "    Found MemoryEventSettings - disable it"
        $node.SetAttribute("enabled", "false");
      }

      Write-Host "  Saving file..."
      $xml.Save($strFileName)
      Write-Host "  File was saved after modification"
    } 
    Else 
    {
      Write-Host "  File does not exist"
    }
    
}

$Websites = Get-ChildItem IIS:\Sites 
foreach($Site in $Websites)
{
    $name = $Site.name
    Write-Host "Web site $name"

    DisableMemoryCollection $Site.physicalPath
}

$applications = Get-WebApplication
foreach($app in $applications)
{
    $name = $app.name
    Write-Host "Application $name"
    DisableMemoryCollection $app.physicalPath
} 
```