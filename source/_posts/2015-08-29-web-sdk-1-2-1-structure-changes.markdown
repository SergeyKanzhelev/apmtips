---
layout: post
title: "Web SDK 1.2.1 structure changes"
date: 2015-08-29 00:00:00 -0700
comments: true
categories:
---
*This blog post was written by Anastasia Baranchenkova*

In version 1.2.1 there were 2 major changes in the structure.



1. All Web SDK assemblies were renamed:

	- Microsoft.ApplicationInsights.Web.dll was renamed on Microsoft.AI.Web.dll
	- Microsoft.ApplicationInsights.Extensibility.Web.TelemetryChannel.dll was renamed on Microsoft.AI.ServerTelemetryChannel.dll
	- Microsoft.ApplicationInsights.Extensibility.PerfCounterCollector.dll was renamed on Microsoft.AI.PerfCounterCollector
	- Microsoft.ApplicationInsights.Extensibility.DependencyCollector.dll was renamed on Microsoft.AI.DependencyCollector.dll	

2. Logic that does not depend on web was moved out from Microsoft.ApplicationInsights.Extensibility.Web to Microsoft.AI.WindowsServer. 

Microsoft.AI.WindowsServer.dll is distributed with the new nuget package [Application Insights Windows Server](http://www.nuget.org/packages/Microsoft.ApplicationInsights.WindowsServer/). This nuget package can be installed on Worker roles projects, windows services or console applications. 

The following telemetry initailizers are part of this assembly (all of them were part of web sdk assembly before):


- DeviceTelemetryInitializer. This telemetry initailizer fills most of device context properties. 
- DomainNameRoleInstanceTelemetryInitializer. This telemetry initializer sets device context RoleInstance to machine FQDN name.
- BuildInfoConfigComponentVersionTelemetryInitializer. This telemetry initializer sets component context Version property using buildinfo.config if you have msbuild integration.
- AzureRoleEnvironmentTelemetryInitializer. This telemetry initailizer sets RoleInstance and RoleInstanceName in case if your application is web or worker role.

The following telemetry modules are part of this assembly:

- DeveloperModeWithDebuggerAttachedTelemetryModule. This module enables VS F5 experience.
- UnhandledExceptionTelemetryModule. This **new module** tracks unhandled exceptions in case if your application is a worker role, windows service or console application.
- UnobservedExceptionTelemetryModule. This **new module** tracks task unobserved  exceptions. 

Additionally this new nuget package changes ApplicationInsights.config file properties so it is copied to the output. Without that in the previous SDK version worker role monitoring did not start till you manually did the same. 
