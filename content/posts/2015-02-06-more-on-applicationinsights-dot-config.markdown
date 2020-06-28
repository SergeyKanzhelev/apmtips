---
layout: post
title: "More on ApplicationInsights.config"
date: 2015-02-06 09:04:12 -0800
comments: true
categories:
- Application Insights 
---
If you were using my instructions on [proxying Application Insights data](/blog/2014/12/19/proxy-application-insights-events/) - please note that format of configuration file has changed and you should not use tag "InProcess" when specifying an endpoint. I updated that post and want to explain how ApplicationInsights.config instantiates objects. This applies to every object you can configure in this configuration file - be it TelemetryInitializer, ContextInitializer, TelemetryModule or Channel.

Main idea behind ApplicationInsights.config file is that this config file should not be required. In ideal world all aspects of monitoring should be coded into your application. That's why we try to avoid any dependencies on file format or schema for SDK objects.

Every object you can configure in ApplicationInsights.config can define "Type". It also may have any number of child xml nodes which will be used to initiate corresponding properties of constructed object. For instance the following configuration snippet will construct object of type "ApmTips.Tools.PropertiesContextInitializer, ApmTips.Tools" and assign value "Bar" to property "Foo". Since this object is defined in ContextInitializers section Application Insights SDK will ensure that class implements "IContextInitializer" interface.

``` xml
<ContextInitializers>
  <Add Type="ApmTips.Tools.PropertiesContextInitializer, ApmTips.Tools">
    <Foo>Bar</Foo>
  </Add>
</ContextInitializers>
```

Corresponding class should look like this:
```
namespace ApmTips.Tools
{
    using Microsoft.ApplicationInsights.DataContracts;
    using Microsoft.ApplicationInsights.Extensibility;

    public class PropertiesContextInitializer : IContextInitializer
    {
        public string Foo { get; set; }

        public void Initialize(TelemetryContext context)
        {
            context.Properties["Foo"] = this.Foo;
        }
    }
}
```
And when you run a program it will add additional property "Foo" with the value "Bar" to every telemetry data item:

``` json
{
  "name":"Microsoft.ApplicationInsights.Request",
  "time":"2015-02-06T17:13:21.1222232+00:00",
  "iKey":"key",
  "tags":{
    ...
    "ai.device.model":"Surface Pro 3",
    "ai.device.machineName":"sergey-surface",
    "ai.operation.name":"GET Home/Index",
    "ai.operation.id":"3518850146076059859"
  },
  "data":{
    "baseType":"RequestData",
    "baseData":{
      "name":"GET Home/Index",
      "startTime":"2015-02-06T17:13:21.1222232+00:00",
      "duration":"00:00:02.5762099",
      "responseCode":"200",
      ...
      "properties":{
        "Foo":"Bar",
      }
    }
  }
}
```

This will apply to TelemetryChannel node as well. You can override the Type attribute of this node to specify your own channel. ["DeveloperMode"](/blog/2015/02/02/developer-mode/) and ["EndpointAddress"](/blog/2014/12/19/proxy-application-insights-events/) are just public properties of the InProcessTelemetryChannel class that is assumed when Type is not specified.