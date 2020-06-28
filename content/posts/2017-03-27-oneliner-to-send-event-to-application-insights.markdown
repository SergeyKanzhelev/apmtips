---
layout: post
title: "Oneliner to send event to Application Insights"
date: 2017-03-27 08:27:16 -0700
comments: true
aliases: [/blog/2017/03/27/oneliner-to-send-event-to-application-insights/]
categories: 
---
Sometimes you need to send event to Application Insights from the command line and you cannot download the `ApplicationInsights.dll` and use powershell script like described [here](https://vnextengineer.azurewebsites.net/powershell-application-insights/). You may need it for your startup task or deployment script. It's a good thing Application Insights has an easy to use REST API. Here is a single line command line that runs powershell and pass the script as a parameter. I split it into multiple lines for readability, you will need to remove all newlines before running. Just replace an event name and add custom properties if needed:

```
powershell "$body = (New-Object PSObject 
    | Add-Member -PassThru NoteProperty name 'Microsoft.ApplicationInsights.Event' 
    | Add-Member -PassThru NoteProperty time $([System.dateTime]::UtcNow.ToString('o')) 
    | Add-Member -PassThru NoteProperty iKey "1aadbaf5-1497-ae49-8e89-cd0324aafe6b" 
    | Add-Member -PassThru NoteProperty tags (New-Object PSObject 
    | Add-Member -PassThru NoteProperty 'ai.cloud.roleInstance' $env:computername 
    | Add-Member -PassThru NoteProperty 'ai.internal.sdkVersion' 'one-line-ps:1.0.0') 
    | Add-Member -PassThru NoteProperty data (New-Object PSObject 
        | Add-Member -PassThru NoteProperty baseType 'EventData' 
        | Add-Member -PassThru NoteProperty baseData (New-Object PSObject 
            | Add-Member -PassThru NoteProperty ver 2 
            | Add-Member -PassThru NoteProperty name 'Event from one line script' 
            | Add-Member -PassThru NoteProperty properties (New-Object PSObject 
                | Add-Member -PassThru NoteProperty propName 'propValue')))) 
    | ConvertTo-JSON -depth 5; 
    Invoke-WebRequest -Uri 'https://dc.services.visualstudio.com/v2/track' -Method 'POST' -UseBasicParsing -body $body" 
```

Running it will return the status:

```
StatusCode        : 200
StatusDescription : OK
Content           : {"itemsReceived":1,"itemsAccepted":1,"errors":[]}
RawContent        : HTTP/1.1 200 OK
                    x-ms-session-id: 960F3184-51B6-4E74-B113-88ACD106B7F3
                    Strict-Transport-Security: max-age=31536000
                    Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Name, Content-Type,...
Forms             :
Headers           : {[x-ms-session-id, 960F3184-51B6-4E74-B113-88ACD106B7F3], [Strict-Transport-Security,
                    max-age=31536000], [Access-Control-Allow-Headers, Origin, X-Requested-With, Content-Name,
                    Content-Type, Accept], [Access-Control-Allow-Origin, *]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        :
RawContentLength  : 49
```

And event will look like this in Application Insights Analytics. 

| name                   | value                                |
|------------------------|--------------------------------------|
| timestamp              | 2017-03-27T15:25:11.788Z             |
| name                   | Event from one line script           |
| customDimensions       | {"propName":"propValue"}             |
| client_Type            | PC                                   |
| client_Model           | Other                                |
| client_OS              | Windows 10                           |
| client_IP              | 167.220.1.0                          |
| client_City            | Redmond                              |
| client_StateOrProvince | Washington                           |
| client_CountryOrRegion | United States                        |
| client_Browser         | Other                                |
| cloud_RoleInstance     | SERGKANZ-VM                          |
| appId                  | d4cbb70f-f58f-ac6d-8457-c2e326fcc587 |
| appName                | test-application                     |
| iKey                   | 1aadbaf5-1497-ae49-8e89-cd0324aafe6b |
| sdkVersion             | one-line-ps:1.0.0                    |
| itemId                 | 927362e0-1301-11e7-88a4-211449da9ad2 |
| itemType               | customEvent                          |
| itemCount              | 1                                    |


Note, sender's IP address and location was added to the event. Also powershell will set the `User-Agent` like this `User-Agent: Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.15063.0` so Application Insights detected that event was sent from `Windows 10` machine.

It is much easier to use Application Insights using one of [numerous SDKs](https://github.com/microsoft/Applicationinsights-home), but when you need it - you can send data directly.