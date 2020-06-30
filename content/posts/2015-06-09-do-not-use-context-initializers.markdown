---
layout: post
title: "Do not use Context Initializers"
date: 2015-06-09 08:10:21 -0700
comments: true
aliases: [/blog/2015/06/09/do-not-use-context-initializers/]
categories:
- Application Insights
---
I've been already writing about [telemetry initializers](/blog/2014/12/01/telemetry-initializers/). Using them you can add custom properties to telemetry items reported by your application. For every telemetry item ```Initialize``` method of all configured telemetry initializer will be called.

Typical use of telemetry initializer is to set properties like user name, operation ID or timestamp. If you look at ```ApplicationInsights.config``` file you'll find a list of default [telemetry initializers](https://azure.microsoft.com/documentation/articles/app-insights-configuration-with-applicationinsights-config/#telemetry-initializers) used for web applications monitoring.

You'd also discover a set of [context initializers](https://azure.microsoft.com/documentation/articles/app-insights-configuration-with-applicationinsights-config/#context-initializers) defined in the standard ```ApplicationInsights.config``` file.

The difference between telemetry initializer and context initializer is that context initializer will only be called once per ```TelemetryClient``` instance. So context initializers collects information that is not specific to telemetry item and will be the same for all telemetry items. Examples may be application version, process ID and computer name.

So why you should **NOT** use context initializer?

***Reason 1***. *You never know when context initializer will be called.*

Context initializers will be called no later than the first access to ```Context``` property of ```TelemetryClient``` object instance will be made. If the only ```TelemetryClient``` object is one you constructed - you can control when context initializers will be executed. However if you are using features like requests monitoring, dependencies monitoring or performance counters collection - number of telemetry clients will be created under the hood. So if you add context initializer to ```TelemetryConfiguration.Active.ContextInitializers``` collection programmatically you can never guarantee that those ```TelemetryClient``` objects were not initialized already.

In fact with the changes in 0.16 SDK some initialization ordering was changed and if you'll add context initializer programmatically in ```Global.asax``` to the ```TelemetryConfiguration.Active.ContextInitializers``` collection - it will NOT be run for web requests telemetry module. So requests and exception items will not be stamped with the properties you need.

***Reason 2***. *Once set it cannot be unset.*

There are cases when you want to change globally set properties in running application. For instance you may need to change environment name from pre-production to production after VIP swap. You cannot achieve it using context initializers. You can remove context initializer from the collection ```TelemetryConfiguration.Active.ContextInitializers```, but properties set by it will still be attached to telemetry items reported from the already created instances of ```TelemetryClient```.

***Reason 3***. *You can do it with telemetry initializer.*

You can always use telemetry initializer instead of context initializer. The only thing you need to do is to cache the property value you need to set so it will not be calculated every time.

So instead of context initializer that will set application version like this:

``` csharp
public class AppVersionContextInitializer : IContextInitializer
{
    public void Initialize(TelemetryContext context)
    {
        context.Component.Version = GetApplicationVersion();
    }
}
```

you can create telemetry initializer that will do the same:

``` csharp
public class AppVersionTelemetryInitializer : ITelemetryInitializer
{
    string applicationVersion = GetApplicationVersion();

    public void Initialize(ITelemetry telemetry)
    {
        telemetry.Context.Component.Version = applicationVersion;
    }
}
```

***Reason 4***. *Context initializer name is confusing.*

If you think what context initializer is doing - it initializes ```TelemetryClient```, not telemetry context. If you'll construct an instance of ```TelemetryContext``` context initializer will not be called. So why is it called context initializer and not client initializer? My telemetry item also have a context. Will context initializer be called when it is constructed? And why not?

The whole reason I'm writing this article is that we regularly getting questions about it and found out that the concept of context initializer if very confusing.

So even if you understood the concept - somebody else may be confused by it and hit a problem with initialization ordering. It is typically hard to troubleshoot why some properties were not added to your telemetry items in production, especially if the issues is timing specific.


The biggest reason we still have a concept of Context Initializer is to keep backward compatibility and do not break existing context initializers you might already have. We are thinking of moving away from context initializers in the future versions and mark this interface as deprecated.
