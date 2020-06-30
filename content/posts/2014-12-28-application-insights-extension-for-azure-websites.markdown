---
layout: post
title: "Application Insights extension for azure websites..."
date: 2014-12-28 10:55:01 -0800
comments: true
aliases: [/blog/2014/12/28/application-insights-extension-for-azure-websites/]
categories:
- Application Insights
- configuration 
---
...and configuring Application Insights when you don't have access to sources.

There is no right answer on whether [Service Oriented Architecture](http://en.wikipedia.org/wiki/Service-oriented_architecture) is good or bad. Some people likes it. Some are using Azure WebSites to build applications with this paradigm in mind as Azure WebSites are cheap, easy to manage, fast to deploy and scale. With service oriented architecture for every particular web site it's important to understand not only how this web site behaves, but also how your "dependencies" - services you are calling into - are doing.

Application Insights allows to monitor dependencies for your application. Today to track dependencies Application Insights using [Profiling API](http://msdn.microsoft.com/en-us/library/bb384493.aspx) to inject code into every http and sql call. You will need to use [Status Monitor](http://azure.microsoft.com/en-us/documentation/articles/app-insights-monitor-performance-live-website-now/) to enable it. However Status Monitor can't be used for azure web site. That's why we just released Azure WebSite extension.

This [very first release of Application Insights Azure WebSite extension](http://www.siteextensions.net/packages/Microsoft.ApplicationInsights.AzureWebSites/) works in assumption that your application has Application Insights of version 0.12+ already configured. Once installed for your WebSite ([go to extensions tab and click "Add"](http://azure.microsoft.com/blog/2014/06/20/azure-web-sites-extensions/)), it will enable collection of dependencies information for your Azure WebSite. 

In future releases Application Insights Azure WebSite extension will enable Application Insights for any application - even if it doesn't have Application Insights configured. I want to show you a small hack that you can use to enable Application Insights for an WebSite that you cannot recompile. This post will not have many technical details - just step-by-step instruction with the pictures.

Ok, imagine you have an application. For example it may be Orchard CMS blog from gallery: 

- Create Azure WebSite from gallery. Use Orchard CMS as a template

![create orchard1 application](/images/2014-12-28-application-insights-extension-for-azure-websites/01-create-orchard-app.png)

- Configure Orchard. I've used Azure SQL server as Application Insights wouldn't monitor SQL CE

![configure orchard](/images/2014-12-28-application-insights-extension-for-azure-websites/02-configure-orchard.png ""  %}

- You can always connect to your web site using WebMatrix. Here magic starts. Download your web site locally

![open in webmatrix](/images/2014-12-28-application-insights-extension-for-azure-websites/03-open-in-webmatrix.png)

- Once downloaded I created new web site on my local IIS server  

![create web site in IIS](/images/2014-12-28-application-insights-extension-for-azure-websites/04-create-web-site-in-iis.png )

- This was a hack that I mentioned. Now as you have a web site on your local server you can use Status Monitor to add Application Insights to it

![enable application insights for web site](/images/2014-12-28-application-insights-extension-for-azure-websites/05-enable-application-insights-for-web-site.png )

- Now when you'd attempt to upload changes - it will upload all changes Status Monitor did

![upload changes](/images/2014-12-28-application-insights-extension-for-azure-websites/06-upload-changes.png)

- I haven't installed extension for my Azure WebSite. So I see requests to Orchard CMS, but do not see dependencies yet

![no dependencies yet](/images/2014-12-28-application-insights-extension-for-azure-websites/07-no-dependencies-yet.png )

- Now you go to extensions blade and enable Application Insights extension

![enable extension](/images/2014-12-28-application-insights-extension-for-azure-websites/08-enable-extension.png )

- Very next request to your azure web site will run a bit longer - Application Insights instrumenting your application. After this you most probably wouldn't notice the noise created by monitoring dependencies. You can see how long your Azure WebSite spent in every dependency. You can see that Orchard has two dependency out of the box - http and sql  

![dependencies chart](/images/2014-12-28-application-insights-extension-for-azure-websites/09-dependencies-chart.png )

- You can also see what exact external calls were made for every particular request:

![dependencies for request](/images/2014-12-28-application-insights-extension-for-azure-websites/10-dependencies-for-request.png)

It is very easy to use Application Insights Azure WebSite extension. It is also easy to configure Application Insights from Visual Studio. You can also enable Application Insights to your web site even if you cannot recompile it - Status Monitor and a simple hack - registering it in local IIS - will help you. 