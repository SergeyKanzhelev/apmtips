---
layout: post
title: "bug with StatusMonitor 5.0 uninstall"
date: 2015-02-28 08:53:35 -0800
comments: true
categories: 
- Application Insights
- troubleshooting
- fix it
---
Once you've started using Application Insights it is essential to install [Status Monitor](http://go.microsoft.com/fwlink/?linkid=506648&clcid=0x409). Status Monitor will enable dependencies tracking as mentioned in one of the [previous posts](/blog/2015/01/05/track-dependencies-in-console-application/). We use Status Monitor to track dependencies for our own internal services. As Brian Harry wrote about [Visual Studio Online services](http://blogs.msdn.com/b/bharry/archive/2014/07/31/explanation-of-july-18th-outage.aspx) "smaller services are better" we have quite a few interconnected services. Knowing that service you depend on became slower or started failing at a glance is very important.  

As we monitor our own services with Application Insights - for some of our services we have startup task that installs Status Monitor. Month ago a small bug in Status Monitor was **one** of the reasons of quite a serious [outage](http://blogs.msdn.com/b/vsoservice/archive/2015/02/05/issues-with-application-insights-performance-metric-service-2-5-investigating.aspx).

Status Monitor in a nutshell is just an installer of Application Insights components and UI to see status of monitoring (as name suggests). By itself it doesn't collect any application telemetry or running any background services. So you may ask - why I'm saying that Status Monitor caused the outage?

And the answer is simple. We are committed to dog food. So we try to run the latest bits of Application Insights SDK and every service restart we are trying to download the latest components. Unfortunately, Status Monitor 5.0 has an issue - when it uninstalls it leaves some registry settings in bad state. Specifically, it make Environment string empty for these three services:

```	
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\IISADMIN
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\W3SVC
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\WAS
``` 

So after uninstall IIS will try to start and will fail as it doesn't expect Environment string to be empty. Here is how it surfaced when you run iisreset /start command:

```
The IIS Admin Service or the World Wide Web Publishing Service, or a service dependent on them failed to start.  The service, or dependent services, may had an error during its startup or may be disabled
```
And these messages you'll see in Event Log:

```
Log Name:      System
Source:        Microsoft-Windows-IIS-IISReset
Date:          2/25/2015 9:08:15 AM
Event ID:      3201
Task Category: None
Level:         Information
Keywords:      Classic
User:          N/A
Computer:      sergey-surface
Description:
IIS start command received from user SERGEY-SURFACE\Sergey. The logged data is the status code.
```

```
Log Name:      System
Source:        Service Control Manager
Date:          2/25/2015 9:08:15 AM
Event ID:      7000
Task Category: None
Level:         Error
Keywords:      Classic
User:          N/A
Computer:      sergey-surface
Description:
The Windows Process Activation Service service failed to start due to the following error: 
The parameter is incorrect.
```

```
Log Name:      System
Source:        Service Control Manager
Date:          2/25/2015 9:08:15 AM
Event ID:      7001
Task Category: None
Level:         Error
Keywords:      Classic
User:          N/A
Computer:      sergey-surface
Description:
The World Wide Web Publishing Service service depends on the Windows Process Activation Service service which failed to start because of the following error: 
The parameter is incorrect.
```

Solution is simple - right after uninstall of Status Monitor 5.0 - install the new one or delete "Environment" string from registry keys mentioned above.

There will be some excited features coming in Status Monitor in future and I hope you will never run into issue upgrading it.