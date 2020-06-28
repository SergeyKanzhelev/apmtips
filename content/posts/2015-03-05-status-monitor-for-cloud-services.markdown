---
layout: post
title: "status monitor for cloud services"
date: 2015-03-05 22:00:36 -0800
comments: true
categories: 
- Application Insights
---
Cool article on how to install Status Monitor on [your web role](http://www.greenfinch.ie/how-to-deploy-application-insights-status-monitor-preview-on-a-cloud-service-webrole/). Don't forget to install Microsoft.ApplicationInsights.Web NuGet package for your web project.

Now in order to track dependencies on worker roles you need to do the same and one additional step - set environment variables to tell worker role [where those new components are](/blog/2015/01/05/track-dependencies-in-console-application/):  

``` xml
<ServiceDefinition name="MyService" xmlns="http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition">
   <WorkerRole name="<name>">
      <Runtime>
         <Environment>
            <Variable name="COR_ENABLE_PROFILING" value="1" />
            <Variable name="COR_PROFILER" value="{324F817A-7420-4E6D-B3C1-143FBED6D855}" />
            <Variable name="MicrosoftInstrumentationEngine_Host" value="{CA487940-57D2-10BF-11B2-A3AD5A13CBC0}" />
         </Environment>
      </Runtime>     
   </WebRole>
</ServiceDefinition>
```
More on how to set environment variables for your worker role is [here](https://msdn.microsoft.com/en-us/library/azure/gg432991.aspx).

Don't forget to install NuGet package Microsoft.ApplicationInsights.RuntimeTelemetry on your worker role and instantiate TelemetryClient at least once on worker role startup.