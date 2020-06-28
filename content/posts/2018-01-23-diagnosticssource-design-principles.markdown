---
layout: post
title: "DiagnosticsSource design principles"
date: 2018-01-23 09:44:46 -0800
comments: true
categories: 
---
Diagnostics Source is a .NET package designed to allow reliable and fast instrumentation of client libraries and platforms. This instrumentation is used by monitoring and diagnostics tools. Diagnostics Source defines the data structure and practices that allow to collect the right level of details. Monitoring tools can fine tune data collection without update of client library code or using fragile code injection techniques.

# Motivation 

Every application has dependencies. With the rise of micro-services architecture even small tasks now implemented as a separate service. Understanding of behavior and reliability of dependent services is crucial to monitor and troubleshoot the health of an application. 

There are many ways and purposes to observe an application. One can collect basic statistics of the service behavior in production or debug an issue in QA environment. There are also tools combining approaches. These tools provide a smart way to "debug" in production. They are using heuristics or user input to tune the level of details to collect ranging from basic statistics to debug snapshot of an entire process. 

Agility of development that comes from customers demand and enabled by micro-services architecture makes the task of creating monitoring tools hard. Applications use different versions of client libraries to access dependant services. Every client library exposes information needed for monitoring in its own way. Monitoring tools use fragile and version-dependant code injection techniques to gather extra information when needed.

Diagnostics Source in .NET was designed to improve observe-ability of libraries and platforms by monitoring tools. It decouples pub from sub, and gives control over level of data collection while maintaining ambient context.

# Design principles

There is a [usage guide](https://github.com/dotnet/corefx/blob/master/src/System.Diagnostics.DiagnosticSource/src/ActivityUserGuide.md) explaining how to use `DiagnosticsSource`. This guide doesn't cover the reasoning for this design. There are five main principles of `DiagnosticsSource` design.

## 1. Minimize versions hell between pubs and subs

There are two models to expose telemetry from client library. Let's call them **define** and **contribute**. With the **define** model, library exposes callbacks specific to its version. Callbacks has semantics defined by this library. Consumer of these callbacks should be library and version aware. **Contribute** model requires library to take dependency on common infrastructure. Library contributes its telemetry in a shape that this infrastructure defines. So library becomes infrastructure and version aware.

`DiagnosticsSource` requires client libraries to take dependency on it. Since every library has its own pace of development - different libraries have dependencies on different versions of `DiagnosticsSource`. So `DiagnosticsSource` should update versions on slow pace and has a high bar for backward compatibility. Developing `DiagnosticsSource` as part of .NET framework addresses this problem. It is easy to take dependency on it and it changes on slow pace. 

On the other hand, subscriber for the `DiagnosticsSource` callbacks may not catch up to the speed of client libraries development. So some information exposed by these libraries is designed to be available by agreement rather than by strong reference. More details you want to collect - more aware subscriber should be of client library specifics.


## 2. Always exists - take it from thin air

Another design principle is that the use of `DiagnosticsSource` should not require the change in client library API. In .NET world, it is NOT a common practice to pass context or telemetry objects into API explicitly. `DiagnosticsSource` exists as a global singleton and .NET makes it cheap to instantiate and start using it.

It also provides an ambient context propagation. Maintaining of ambient context ensures that libraries do not need to know about each other to collaborate. You can always rely on "current" context. This feature is specific for .NET. Other languages like Go may implement framework-provided context class.


## 3. Single instrumentation for multiple purposes

The ultimate way to improve performance of an infrastructure is to remove this infrastructure. Having monitoring callbacks is not free. Having multiple monitoring callbacks makes code less reliable and affects its performance. Typical client library exposes information for distributed tracing, logging and for the diagnostics tools. `DiagnosticsSource` was designed to satisfy these scenarios with the minimal overhead. APIs of `DiagnosticsSource` designed to expose a lot of information and for subscribers to be able to limit information that needs to be collected. And make it fast and reliably.

## 4. Unopinionated semantics

`DiagnosticsSource` is used by many subscribers with the different needs - from stats collection to rich diagnostics experiences. It also needs to have a stable API surface to minimize the version revisions. So the API surface of `DiagnosticsSource` is minimal and not opinionated. For instance, there are tools that have a notion of annotations of the distributed trace's span. Other tools send annotations as independent events or not collect them all the time. `DiagnosticsSource` recommend exposing annotations as a separate events and subscriber needs to decide what to do with it.

## 5. You did it wrong! but now worries...

The significant problem monitoring tools experience with libraries instrumentation is that instrumentation callbacks become less and less relevant over time. Tools require more data to be collected. Or to collect this data in a different format. `DiagnosticsSource` designed to expose raw objects. So tools may start collecting more telemetry when required without client library modification. It is especially critical for the client libraries that change infrequently or has a long approval process. Modification of the code that enables monitoring may be slow due to backward compatibility, compliance, or other requirements.

# Other languages and platforms

The analog of .NET `DiagnosticsSource` can be useful for other languages as well. For node.js, there is a [diagnostics channel](https://github.com/Microsoft/node-diagnostic-channel). There is [discussion](https://github.com/nodejs/diagnostics/issues/134) to make diagnostics channel a standard or even part of node.js SDK. There are more opportunities for other languages and platforms. 

