---
layout: post
title: "more telemetry channels"
date: 2015-09-03 09:12:44 -0700
comments: true
aliases: [/blog/2015/09/03/more-telemetry-channels/]
categories: 
- Application Insights
---
Application Insights SDK works on [many platforms](https://azure.microsoft.com/documentation/articles/app-insights-platforms/). You can use it to send telemetry [Desktop applicaitons](/blog/2015/08/08/application-insights-for-desktop-applications/), web services, phone apps. All these platforms has their specifics. Phone and desktop apps typically has as single user and small number of events from every particular instance of applicaiton. Services serves many users the same time and have very high load. Devices can go online and offline very often. Services are typically always online.

Initial versions of Applicaiton Insights SDK attempted to have a single channel that will account for all these differences. However we found that it is not easy to accomodate them in a single channel. So now we have three different channel implementations:

- InMemoryChannel  
- Persistence channel for devices
- Windows Server telemetry channel

Sampling that I mentioned in [this post](/blog/2015/05/06/diy-data-sampling/) mostly applies to the windows server telemetry channel. So I've updated that post.

##InMemoryChannel
InMemory channel ```Microsoft.ApplicationInsights.Channel.InMemoryChannel``` is a lightweight loosy telemetry channel that is used by default. It will batch data and initiate sending every ```SendingInterval``` (default is 30 seconds) or when number of items exceeded ```MaxTelemetryBufferCapacity``` (default is 500. It also will not retry if it failed to send telemetry. 

***Package:*** this channel is part of [Applicaiton Insights API package](https://www.nuget.org/packages/Microsoft.ApplicationInsights/).
***Sources:*** [InMemoryChannel.cs on github](https://github.com/Microsoft/ApplicationInsights-dotnet/blob/1648ecd5bf32cc151557d15cbb0886cb86e84270/src/Core/Managed/Shared/Channel/InMemoryChannel.cs).

##Persistence channel for devices
Persistence channel for devices ```Microsoft.ApplicationInsights.Channel.PersistenceChannel``` is a channel optimized for devices and mobile apps and works great in offline scenarios. It requires a file storage to persist the data and you should use [this constructor](https://github.com/Microsoft/ApplicationInsights-dotnet/blob/1648ecd5bf32cc151557d15cbb0886cb86e84270/src/TelemetryChannels/PersistenceChannel/Shared/PersistenceChannel.cs#L53) to specify folder you want to use for storage. 

I already [explained](/blog/2015/08/08/application-insights-for-desktop-applications/) how this channel will work for unhandled exceptions. It writes events to disk before attempting to send it. Next time app starts - event will be picked up and send to the cloud. Furthermore, if you are running multiple instances of an applicaiton - all of them will write to the disk, but only one will be sending data to http endpoint. It is controled via [global Mutex](https://github.com/Microsoft/ApplicationInsights-dotnet/blob/1648ecd5bf32cc151557d15cbb0886cb86e84270/src/TelemetryChannels/PersistenceChannel/Shared/PersistenceTransmitter.cs#L47).   

***Package:*** [Application Insights Persisted HTTP channel](http://www.nuget.org/packages/Microsoft.ApplicationInsights.PersistenceChannel/) 
***Sources:*** [PersistenceChannel.cs on github](https://github.com/Microsoft/ApplicationInsights-dotnet/blob/1648ecd5bf32cc151557d15cbb0886cb86e84270/src/TelemetryChannels/PersistenceChannel/Shared/PersistenceChannel.cs)

##Windows Server telemetry channel
Windows Server telemetry channel ```Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel.ServerTelemetryChannel``` is a channel optimized for high volume data delivery. It will send data to endpoint first and only attempt to persist data if endpoint cannot be reached. It is using current user's local app data folder (```%localAppData%\Microsoft\ApplicationInsights```) or temp folder (```%TMP%```).

This channel implements exponential retry intervals and respect ```Retry-After``` header set by the server. It solves the problem we call "spiral of death". Spiral of death happens when endpoint was temporary unavbailable or you hit the throttling limit. Channel starts persisting data if it cannot send it. After some time your throttling limit will be cleared up or connectivity issue will be fixed. So channel will start sending all the new and persisted data. With the big load you may hit throttling limit very easily again. So data will be rejected again. And you'll start persiting it entering the spiral.

***Package:*** [Windows Server telemetry channel](http://www.nuget.org/packages/Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel/)
***Sources:*** Not public yet.


##Summary
Different applications requires different channels. NuGet packages will configure proper channel for you. However if you configure Application Insights manually you need to know which channel is right for you.
