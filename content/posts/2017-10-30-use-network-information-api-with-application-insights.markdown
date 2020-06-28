---
layout: post
title: "Use Network Information API with Application Insights"
date: 2017-10-30 16:00:56 -0700
comments: true
aliases: [/blog/2017-10-30-use-network-information-api-with-application-insights/]
categories: 
- DIY
---

Recently Chrome [enabled](https://www.chromestatus.com/feature/6338383617982464) support of [Networking API](https://wicg.github.io/netinfo/#toc). The main idea of the API is to give you control over site behavior on weak connection. The first step to decide how much to invest into network-specific optimizations is to collect statistics. Here is how you can do it with Application Insights JavaScript SDK.

There are two things you may want to do. First, extend all events with the network properties information. You can analyze how long page loads on all connections or how AJAX calls behavior changes on weak networks. Second - track network switches. For long living pages like SPA applications, this statistic may be interesting.

## Network properties

This example shows how to add network properties to all telemetry items sent from the page.

``` js
appInsights.queue.push(() => {
  appInsights.context.addTelemetryInitializer((envelope) => {
    var telemetryItem = envelope.data.baseData;

    telemetryItem.properties = telemetryItem.properties || {};
    try {
      telemetryItem.properties["navigator.connection.type"] = navigator.connection.type;
      telemetryItem.properties["navigator.connection.downlink"] = navigator.connection.downlink;
      telemetryItem.properties["navigator.connection.rtt"] = navigator.connection.rtt;
      telemetryItem.properties["navigator.connection.downlinkMax"] = navigator.connection.downlinkMax;
      telemetryItem.properties["navigator.connection.effectiveType"] = navigator.connection.effectiveType;
    } catch (e) {
      telemetryItem.properties["navigator.connection.type"] = "Navigation API not supported";
    }
  });
});
```

I'm traveling today. This picture shows what I saw in airport:

{% img /images/2017-10-30-use-network-information-api-with-application-insights/network_in_airport.png  'Network in airport' %}

Once I connected to the internet in plane I see other values:

{% img /images/2017-10-30-use-network-information-api-with-application-insights/network_in_plane.png  'Network in the plane' %}

You can query analyze pageViews now using simple query:

```
pageViews 
  | summarize sum(itemCount) by tostring(customDimensions["navigator.connection.effectiveType"])
```

## Network change event

To get the network change event, you need to subscribe on `change` event. When function called - track an event with the new network properties.

``` js
navigator.connection.addEventListener('change', logNetworkInfo);

function logNetworkInfo() {
  appInsights.trackEvent("NetworkChanged", {
    "navigator.connection.type": navigator.connection.type,
    "navigator.connection.downlink": navigator.connection.downlink,
    "navigator.connection.rtt": navigator.connection.rtt,
    "navigator.connection.downlinkMax": navigator.connection.downlinkMax,
    "navigator.connection.effectiveType": navigator.connection.effectiveType
  });
}
```

## Summary

As you see, it's straightforward to enrich your telemetry. You may now better understand your customers. Based on telemetry you can prioritize optimizing your site for faster or slower networks.