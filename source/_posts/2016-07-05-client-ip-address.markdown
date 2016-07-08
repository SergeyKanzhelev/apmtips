---
layout: post
title: "client IP address"
date: 2016-07-05 23:15:31 -0700
comments: true
categories: 
---
Client IP address is useful for some telemetry scenarios. You may discover very high latency from remote countries or the reason for a requests count spike in the night when countries across the ocean woke up.

Application Insights collects client IP address. Country, state and city information will be extracted from it and than the last octet of IP address will be set to 0 to make it non-identifiable. So Application Insights will never store an actual IP address by default. 

There are two ways IP address got collected for the different scenarios. 

##Browser and devices 

When telemetry is sent from browser by JavaScript SDK or from device - Application Insights endpoint will collect sender's IP address. Endpoint doesn't resolve as IPv6 so this IP address will always be IPv4.


##Server applications

Client IP address for the server application will be collected by SDK. In .NET it is done by `ClientIpHeaderTelemetryInitializer`. This telemetry initializer [will check](https://github.com/Microsoft/ApplicationInsights-dotnet-server/blob/7c86689810be38a8a8a412c0720a4f2614d7207d/Src/Web/Web.Shared.Net/ClientIpHeaderTelemetryInitializer.cs#L18) `X-Forwarded-For` http header and if it is not set - use client IP.

Caveat here is that Application Insights only supports IPv4 at the moment of this writing. So if the clients of your application are using IPv6 – IP address will not be send to Application Insights.

Now when Application Insights receives an event without IP address set - it will assume that this event came from the device and will store the server's IP address. This is why you may find some [fake Brazilian clients](https://social.msdn.microsoft.com/Forums/en-US/8f1a1285-cd9d-4231-94a5-eef4fc0ca46e/bingcom-thinks-my-azure-vm-is-in-brazil?forum=WAVirtualMachinesforWindows) when your application was deployed in Azure.    

You may also end up getting the firewall/load balancer IP address for all your clients if this firewall sets an original IP address into a different http header. Popular one is `X-Originating-IP`.

It is easy to override the default logic of `ClientIpHeaderTelemetryInitializer` using configuration file. You can set a list of header names to check, separators to split IP addresses and whether to use first or last IP address. Here is how to override default settings: 

``` xml
<Add Type="Microsoft.ApplicationInsights.Web.ClientIpHeaderTelemetryInitializer, Microsoft.AI.Web">
  <HeaderNames>
    <Add>X-Originating-IP</Add>
  </HeaderNames>
  <HeaderValueSeparators>;</HeaderValueSeparators>
  <UseFirstIp>false</UseFirstIp>
</Add>
```

Now, when your application will receive the header `X-Originating-IP: 8.8.8.1;8.8.8.2` telemetry will be sent with the following context property: `"ai.location.ip":"8.8.8.2"`.

If you want to keep the full IP address with your telemetry and storing client's PII information is not a concern - you can implement a telemetry initializer:

``` csharp
public class CopyIPTelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        if (!string.IsNullOrEmpty(telemetry.Context.Location.Ip))
        {
            telemetry.Context.Properties["client-ip"] = telemetry.Context.Location.Ip;
        }
    }
}
```

This telemetry initializer will store IP address in the custom property and it's last octet will not be set to zero. Make sure to add it after `ClientIpHeaderTelemetryInitializer`. 

Another tip - C# SDK do not allow to sent IPv6 addresses to Application Insights. Using custom properties is a good alternative for sending it:

``` csharp
public class IPv6AddressTelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        if (HttpContext.Current != null)
        {
            IPAddress ip;
            if (IPAddress.TryParse(HttpContext.Current.Request.UserHostAddress, out ip))
            {
                telemetry.Context.Properties["client-ip"] = ip.ToString();
            }
        }
    }
}
```

##Where is my map?

Once IP addresses collected properly - the next step is to map them. There is no map in Azure portal. But you can easily visualize your telemetry on the map using [Power BI integration](https://azure.microsoft.com/en-us/documentation/articles/app-insights-export-power-bi/).
