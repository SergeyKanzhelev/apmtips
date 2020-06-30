---
layout: post
title: "New SDK version published"
date: 2015-04-21 07:47:38 -0700
comments: true
aliases: [/blog/2015/04/21/new-sdk-version-published/]
categories:
 - release notes
 - application insights
---
The version 0.15 of [Application Insights SDK](http://www.nuget.org/packages/Microsoft.ApplicationInsights/0.15.0-build00179) was published on NuGet. Good news - this SDK reverts back API changes made in 0.14. Specifically it returns back ```TelemetryContext.Properties``` mentioned [here](/blog/2015/04/11/where-are-the-telemetry-context-properties/).

More changes:

- Couple NuGet packages were renamed to make names more descriptive:
  - PerformanceCollector package renamed to PerfCounterCollector
  - RuntimeTelemetry renamed to DependencyCollector
- New property ```Operation.SyntheticSource``` now available on ```TelemetryContext```. Now you can mark your telemetry items as "not a real user traffic" and specify how this traffic was generated. As an example by setting this property you can distinguish traffic from your test automation from load test traffic.
- Application Insights Web package now detects the traffic from Availability monitoring of Application Insights and marks it with specific SyntheticSource property.
- Channel logic was moved to the separate NuGet called ```Microsoft.ApplicationInsights.PersistenceChannel```.
