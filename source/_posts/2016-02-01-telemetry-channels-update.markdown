---
layout: post
title: "Telemetry channels update"
date: 2016-02-01 00:00:00 -0700
comments: true
categories:
- Application Insights
---
*This blog post was written by Anastasia Baranchenkova*

# Telemetry channels update #

From the time Sergey wrote his [blog post](http://apmtips.com/blog/2015/09/03/more-telemetry-channels/) there are a few changes.

Persistence channel was removed. There will be no new versions of Application Insights SDK for devices. The suggested solution is to use [HockeyApp](http://hockeyapp.net/features/) that Microsoft acquired last year.

Server channel became [open source](https://github.com/Microsoft/ApplicationInsights-dotnet/tree/master/src/TelemetryChannels/ServerTelemetryChannel). 

Also it was mentioned in Sergey’s blog post that Server telemetry channel  stores events on disk if they cannot be sent. The channel would use either current user’s local app data folder or current process temp folder. 
I saw several cases when there was a problems with that.
 
In the [first case](http://stackoverflow.com/questions/34106876/application-insights-no-data-for-dependency-calls/34171132#comment56090477_34171132 ) process did not have access neither to local app data nor to the temp folder. The workaround was to make sure it has it.

Second one was more interesting. There was an application that worked perfectly fine locally but when deployed to a VM it crashed. It appeared that local app data was pointing to an unmapped drive. Unfortunately ApplicationInsights was not catching this type of exception, so it was just crashing without even trying to check temp folder. This bug was fixed in 2.0.0-beta4. 

Additionally fixing this issue we added an ability to specify custom folder either though configuration or in code (if it is not provided or inaccessible old logic is used).

In configuration file you would do it this way (make sure you have correct xml closing tags):

```xml
<TelemetryChannel Type="Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel.ServerTelemetryChannel, Microsoft.AI.ServerTelemetryChannel">
    <StorageFolder>D:\NewTestFolder</StorageFolder>
</TelemetryChannel>
```

In code you would do it this way:

-	Remove ServerTelemetryChannel from configuration file
-	Add this piece of code to the place where application gets initialized:

```
ServerTelemetryChannel channel = new ServerTelemetryChannel();
channel.StorageFolder = @"D:\NewTestFolder";            
channel.Initialize(TelemetryConfiguration.Active);

TelemetryConfiguration.Active.TelemetryChannel = channel;
```

An interesting side note: configuration loading is very flexible. If you see a public property on the object that can be defined in the configuration file (e.g. TelemetryInitializer, TelemetryProcessor or Channel) this property can be set via configuration file. We did not have to change configuration loading logic for this update, we just added a public property to the ServerTelemetryChannel.









