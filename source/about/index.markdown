---
layout: page
title: "about"
date: 2015-01-18 18:06
comments: true
sharing: true
footer: true
---
This is my personal blog based on octopress engine.

Contribute
----------
 You can find all the blog sources at [github](https://github.com/SergeyKanzhelev/apmtips). Feel free to send a pull request. I'll greatly appreciate styling and grammar fixes.

Setup
-----
These are notes on how to get, test and deploy this blog from sources. Apmtips is built on octopress engine and hosted as azure web site. I'm writing posts on my Surface 3 (windows 8.1) so steps may differ for your environment.

Clone blog from github:
```
git clone https://github.com/SergeyKanzhelev/apmtips.git
```

You need these to be installed:

1. Ruby. I'm using [yari](https://github.com/scottmuc/yari): yari 1.9.3
2. Python. I have SET PATH=%PATH%;C:\tools\Python27
3. "Which". I downloaded binaries from [gnuwin32](http://gnuwin32.sourceforge.net/packages/which.htm). SET PATH=%PATH%;c:\tools\which2.20\bin

Once these tools are installed you can generate site: 
```
rake generate
```

I am using IIS to see how it looks before publishing:

```
New-Website -Name apmtips -Port 1211 -PhysicalPath "c:\src\octopress\public"
```

Deploy
------
This is how I configured deployment to azure as azure web site:
```
mkdir _azure
cd _azure
git init
git remote add origin https://apmtips.scm.azurewebsites.net/apmtips.git 
```