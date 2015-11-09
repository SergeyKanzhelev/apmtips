---
layout: post
title: "operational insights agent for SCOM"
date: 2015-09-11 09:28:02 -0700
comments: true
categories:
- SCOM
- Application Insights 
---
Quite unusual tip today. You may heard of System Center Operations Manager and the fact it provides APM capabilities. Where APM stands for Application Performance Monitoring. You may also heard of [Operational Insights](http://azure.microsoft.com/services/operational-insights/) which can work as an attach service for Operations Manager.

What you may not know that the latest agent distributed for Operational Insights is not only compatible with System Center, but also brings more APM capabilities than regular System Center SCOM 2012 R2 agent has. It has number of bugfixes, perf improvements and couple features support like monitoring of MVC 5 applicaitons.

You can download this agent here:  
- [64-bit windows](https://go.microsoft.com/fwlink/?LinkID=517476)
- [32-bit windows](https://go.microsoft.com/fwlink/?LinkID=615592)

Another interesting fact about this agent is that looking into the folder ```%programfiles%\Microsoft Monitoring Agent\Agent\APMDOTNETAgent\V7.2.10375.0\x64``` you will find the files I mentioned in the [post](/blog/2015/01/05/track-dependencies-in-console-application/) explaining how Application Insights tracks dependencies. So installing this agent and enabling APM will help Application Insights SDK collect reacher informaiton about your applicaiton http and SQL dependencies so you don't need to install Status Monitor. 