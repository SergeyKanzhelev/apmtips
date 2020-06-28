---
layout: post
title: "Collecting performance counters"
date: 2015-02-02 08:18:47 -0800
comments: true
aliases: [/blog/2015/02/02/collecting-performance-counters/]
published: false
categories: 
---
With the 0.12 version of Application Insights SDK some windows performance counters are being collected for your application. Collecting windows performance counters is not an easy business. In this blog post I'll try to show some problems you need to work around when working with performance counters. I'll explain the known issues we have today with performance counters collection and will give one advice. 

When collecting performance counters 

Security
--------

When you onboarded your application on 0.12 Application Insights SDK you'll see that some performance counters being collected. Here is the set of counters collected today. Make sure that identity your application is running under is part of [Performance Monitor Users](https://technet.microsoft.com/en-us/library/cc785098.aspx) security group so it has enough permissions to collect them. If you use Status Monitor to enabler monitoring it will warn you and will allow to add application pool identity in this group in one click.  


- CPU ()
- Memory ()



This list is not extendable today. 


Microsoft [KB article](http://support.microsoft.com/kb/281884) 

```
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\PerfProc\Performance\ -Name ProcessNameFormat -Value 2 -PropertyType DWORD
```