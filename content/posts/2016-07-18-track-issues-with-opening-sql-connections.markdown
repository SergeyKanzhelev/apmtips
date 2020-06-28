---
layout: post
title: "Track issues with opening sql connections"
date: 2016-07-18 23:54:22 -0700
comments: true
aliases: [/blog/2016-07-18-track-issues-with-opening-sql-connections/]
published: false
categories: 
---
Every time you need to run a database call you take a connection to the database from a connection pool. Method `Open` on `SqlConnection` will fo it for you. Code will looks something like this:

``` csharp
await cmd.Connection.OpenAsync();
```

However many frameworks will hide this call from you as most probably you do not want to think about opening and closing connection. You need to run a SQL query and this query is what you actually worry about. 

Sql connection may start acting badly. It may fail when database rejects connection. It may run very slow due to DNS or networking issues. When this happens you's say that your application is not working or working slow because of the dependency.

So this method becoming a dependency only when misbehaving.

``` csharp
using (var operation = client.StartOperation<DependencyTelemetry>(string.Join(" | ", cmd.Connection.DataSource, cmd.Connection.Database)))
{
    operation.Telemetry.CommandName = "OpenAsync";
    operation.Telemetry.DependencyKind = "SQL";

    operation.Telemetry.Success = false; // set it to false in case exception will be thrown
    await cmd.Connection.OpenAsync();
    operation.Telemetry.Success = true; // reset it back to true. No exceptions happened
}
```