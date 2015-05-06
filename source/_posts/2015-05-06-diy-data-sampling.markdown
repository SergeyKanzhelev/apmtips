---
layout: post
title: "DIY: data sampling"
date: 2015-05-06 09:07:57 -0700
comments: true
categories:
- Application Insights
- DIY
---
Now when pricing for Application Insights is [announced](http://azure.microsoft.com/en-us/pricing/details/application-insights/) you might be wondering - how can you make these prices truly cloud-friendly and only pay for what you are using. You may also wonder - how to fit into throttling limits even if you are willing to pay for all the telemetry data your application produces. *Note*, you wouldn't need any of this if your application doesn't have a big load. There are great filtering and grouping capabilities in Application Insights UI so you will be better off having all the data on the server.

There are four techniques to minimize the amount of data your application reports - separate traffic, filter not interesting data, sample and aggregate. Today I'll explain how to implement sampling.

Sampling will only work for high-load applications. The idea is to send only every *n*-th request to the server. With the normal distribution of requests and high load you'll get statistically correct values for all sorts of aggregations (don't forget to multiply all values you see in UI to *n*).

There is no out-of-the-box support for sampling or filtering in Application Insights today. So the idea of implementing it will be to replace standard channel with the custom-made. For every telemetry item this channel may decide whether to send it to the portal or not.

First, define a new class. You'll need to have your own instance of ```PersistenceChannel```. I've also defined public property ```SampleEvery``` so you can configure how much data to sample out using configuration file:  

``` c#
public class RequestsSamplingChannel : ITelemetryChannel, ISupportConfiguration
{
    private int counter = 0;

    private PersistenceChannel channel;

    public int SampleEvery { get; set; }

    public RequestsSamplingChannel()
    {
        this.channel = new PersistenceChannel();
    }

    public void Initialize(TelemetryConfiguration configuration)
    {
        this.channel.Initialize(configuration);
    }
}
```

Now you should implement ```Send``` method. In this example I apply sampling only to Requests so performance counters, metrics, dependencies and traces will not be sampled. If telemetry item is of type ```RequestTelemetry``` I'd increment counter and every *SampleEvery*-th time will send this item using standard channel:

``` c#
public void Send(ITelemetry item)
{
    if (item is RequestTelemetry)
    {
        int value = Interlocked.Increment(ref this.counter);
        if (value % this.SampleEvery == 0)
        {
            this.channel.Send(item);
        }
        else
        {
            //value was sampled out. Do nothing
        }
    }
    else
    {
        this.channel.Send(item);
    }
}
```

For all other properties and methods - just proxy them to the standard channel:

``` C#
public bool DeveloperMode
{
    get
    {
        return this.channel.DeveloperMode;
    }
    set
    {
        this.channel.DeveloperMode = value;
    }
}

public string EndpointAddress
{
    get
    {
        return this.channel.EndpointAddress;
    }
    set
    {
        this.channel.EndpointAddress = value;
    }
}

public void Flush()
{
    this.channel.Flush();
}

public void Dispose()
{
    this.channel.Dispose();
}
```

Now you can use this channel. In ```ApplicationInsights.config``` file replace the ```TelemetryChannel``` node with the following. You can read more on how Application Insights SDK instantiate objects from configuration [in my previous post](/blog/2015/02/06/more-on-applicationinsights-dot-config/):

``` xml
<TelemetryChannel Type="ApmTips.RequestsSamplingChannel, ApmTips">
  <SampleEvery>10</SampleEvery>
</TelemetryChannel>
```

You can implement all sort of interesting sampling algorithms using this approach. Instead of counter you can use random generated value or even ```RequestTelemetry.ID``` property that is fairly random.

Next time I'll cover other ways to minimize the amount of data you are sending to Application Insights.
