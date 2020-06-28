---
layout: post
title: "Where are the telemetry context properties?"
date: 2015-04-11 12:49:46 -0700
comments: true
aliases: [/blog/2015-04-11-where-are-the-telemetry-context-properties/]
categories: 
---
Recently the change was made. Upgrading from Application Insights SDK version [0.13](http://www.nuget.org/packages/Microsoft.ApplicationInsights.Web/0.13.3-build03939) to the version [0.14](http://www.nuget.org/packages/Microsoft.ApplicationInsights.Web/0.14.0-build20632) you may notice that some public interfaces were changed. Specifically, public property ```Properties``` was removed from ```TelemetryContext``` class. Yes, one that mentioned in the [documentation](http://azure.microsoft.com/en-us/documentation/articles/app-insights-web-track-usage-custom-events-metrics/#defaults) and [blog post](http://blogs.msdn.com/b/visualstudioalm/archive/2015/01/07/application-insights-support-for-multiple-environments-stamps-and-app-versions.aspx). One that is very important to enable many scenarios.

It is not a change we plan to keep for a long time. Public interface will be reverted back soon.

I thought a lot on how to explain this change and what led to this. Now I know what was the motivation of this change, I can tell that [semantic versioning](http://semver.org/) is designed to experiment with API surface, I know why it wasn't immediately reverted. However I better not to go into details. I want to assure you that we understand that such a big API change should not happen again without the notice.

Version [0.14](http://www.nuget.org/packages/Microsoft.ApplicationInsights.Web/0.14.0-build20632) of SDK brings great new features like ability to monitor custom [performance counters](http://blogs.msdn.com/b/visualstudioalm/archive/2015/04/01/application-insights-choose-your-own-performance-counters.aspx). If you want to use this features and need custom properties I'd recommend to wait for the new version of SDK. If you don't want to wait - here is a workaround (it will only work in 0.14 SDK).

If you are using context initializer - convert it to telemetry initializer. Now in telemetry initializer use ```ISupportProperties``` interface to set properties for telemetry item:

```
public class WorkaroundTelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        var propsTelemetry = telemetry as ISupportProperties;
        if (propsTelemetry != null)
        {
            propsTelemetry.Properties["environment"] = "development";
        }
    }
}
``` 

Again, this workaround will only be needed for the version 0.14 and will not work in the next version of SDK.  