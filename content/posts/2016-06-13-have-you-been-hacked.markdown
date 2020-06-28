---
layout: post
title: "Have you been hacked?"
date: 2016-06-13 14:06:15 -0700
comments: true
aliases: [/blog/2016-06-13-have-you-been-hacked/]
categories: 
- Application Insights
- Security
---
I've returned from the [long](https://blogs.microsoft.com/blog/2015/08/05/the-employee-experience-at-microsoft-aligning-benefits-to-our-culture/) parental leave. Checking telemetry for this blog I noticed the new dependency call

{% img /images/2016-06-13-have-you-been-hacked/01-single-dependency-call.png 'Single dependency call' %}

Here is how it looks on Application map:

{% img /images/2016-06-13-have-you-been-hacked/02-single-dependency-on-map.png 'Single dependency call on the map' %}

It scared me as there are no AJAXes in the blog. So my first thought - my blog was hacked. 

Diving deeper - it is a call to `http://api4.adsrun.net/post`. Looks even scarier. Quick internet search showed that this is a malware installed on visitor's computer. This malware injects malicious code into jquery script that browser loads. So apmtips.com is safe, it's visitor's computer has a security problem. 

Looking into `All available telemetry for this user session` I found some details of the visitor. So if you are visiting from the city of *Sangli* in *India* using Firefox - **check your computer for malware**.