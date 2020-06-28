---
layout: post
title: "Proxy Application Insights events"
date: 2014-12-19 09:33:38 -0800
comments: true
categories: 
- Application Insights 
- troubleshooting
---
Sometimes you want to check that telemetry data is collected by Application Insights SDK and being sent to the endpoint. It is easy to do in Visual Studio - you will see JSON of telemetry items in debug window or use Fiddler to see data being sent by application running in IISEpress. However if your application is running in IIS under application pool identity or local system account Fiddler will not pick up events. It is also challenging to do when application is running in production environment and you don't want to install fiddler there.

Here is how you can do it.

**Install and configure reverse proxy.** I'm using Fiddler as a reverse proxy. It is very simple to [configure it](http://docs.telerik.com/fiddler/configure-fiddler/Tasks/UseFiddlerAsReverseProxy). If you are troubleshooting production environment you can have fiddler on machine accessible from one running your application.

In my example I have fiddler on machine where my application is running. So I used this code snippet in OnBeforeRequest handler:
```
if (oSession.host.toLowerCase() == "localhost:8888") oSession.host = "dc.services.visualstudio.com";
```
You may need to replace "localhost" to the name of machine running fiddler.

**Redirect application Insights SDK traffic to this proxy.** Here is a piece of XML you need to insert into ApplicationInsights.config file of your application. Note, this will work for application Insights SDK 0.12. It had different format for previous versions and may change in future:
``` xml
<TelemetryChannel>
	<InProcess>
		<EndpointAddress>http://localhost:8888/v2/track</EndpointAddress>
	</InProcess>
</TelemetryChannel>
```

***Update***: *Please note, format of configuration file changed in 0.13 SDK. Now you should not specify "InPorcess" tag:*
``` xml
<TelemetryChannel>
  <EndpointAddress>http://localhost:8888/v2/track</EndpointAddress>
</TelemetryChannel>
```

Again, if you are using different machine you will need to replace localhost to the name of machine running your proxy server (or fiddler in my case).

**Redirect JavaScript-generated traffic.** It is rare, but sometimes you may want to redirect JavaScript events. It is rare since JavaScript events may be easily viewed using browser tools and fiddler will always pick them up. However if you want to proxy JavaScript-generated telemetry data from all your customers this may be handy. All you need to do is to add ```endpointUrl``` property in Application Insights JavaScript code snippet:
``` js
{
    instrumentationKey: "e62632f1-81af-41d2-b8e8-9df22f10d9c3",
    endpointUrl: "//localhost:8888/v2/track"
}
```
Now you can see all Application Insights telemetry in fiddler (or other reverse proxy tool).