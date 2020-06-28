---
layout: post
title: "tracking static content with Application Insights HttpModule"
date: 2014-12-02 12:01:01 -0800
comments: true
aliases: [/blog/2014/12/02/tracking-static-content-with-application-insights-httpmodule/]
published: true
categories: 
- Application Insights
---
Application Insights Web Nuget registers itself as [http module](http://msdn.microsoft.com/en-us/library/vstudio/ms227673.aspx) to hook up in IIS request processing pipeline and start collecting requests information. You may notice that it registers both - classic mode http module and integrated mode since we don't know at design time what mode your application will be running in. One caveat here is that this nuget also sets [validateIntegratedModeConfiguration flag](http://msdn.microsoft.com/en-us/library/bb422433.aspx) to false so IIS wouldn't complain on classic mode registration when running in integrated mode.

``` xml
<system.webServer>
  <validation validateIntegratedModeConfiguration="false" />
</system.webServer>
```

Since most application these days running in integrated mode you can safely remove this setting and one of http module registration to keep your ```web.config``` clean.

Since application insights is just a regular http module you can configure it even further. For instance, you may have some static html pages, served by IIS, not by ASP.NET, that you want to monitor - see who and when have accessed them. When running in integrated mode of IIS you can do it by setting [runAllManagedModulesForAllRequests](http://www.iis.net/configreference/system.webserver/modules) to true and remove [precondition=”managedHandler”](http://msdn.microsoft.com/en-us/library/ms690693.aspx) for Application Insights http module. This will start tracking ALL requests to static files as requests. There is no filtering capability so you’ll see all static content and will need to use search explorer on ibiza portal to see specific pages. Here is how your modules section should look after modifications:
``` xml
<system.webServer>
  <modules runAllManagedModulesForAllRequests="true">
    <!--<add name="ApplicationInsightsWebTracking" type="Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.WebRequestTrackingModule, Microsoft.ApplicationInsights.Extensibility.Web" preCondition="managedHandler" />-->
    <add name="ApplicationInsightsWebTracking" type="Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.WebRequestTrackingModule, Microsoft.ApplicationInsights.Extensibility.Web" />
  </modules>
</system.webServer>
```
Once configured you'll start seeing static content as requests collected on portal:
{% img /images/2014-12-02-tracking-static-content-with-application-insights-httpmodule/static-content.png 'static content' %}

Since this blog is statically generated using octopress and hosted as azure web site I plan to use this technique to monitor requests made to it. I'll post an update when will try it.