---
layout: page
title: "about"
date: 2015-01-18 18:06
comments: true
sharing: true
footer: true
---
This is my personal blog. My main interest is application monitoring and [APM](http://en.wikipedia.org/wiki/Application_performance_management) space in general. I amd working in Microsoft on Application Insights and System Center Operations Manager (APM part).

Contribute
----------
You can find all the blog sources at [github](https://github.com/SergeyKanzhelev/apmtips). Feel free to send a pull request if you found some error or want to help to make posts better. 

Setup
-----
You can easily setup octopress locally to test and deploy this blog from sources. Apmtips is built on octopress engine and hosted as azure web site. I'm writing posts on my Surface 3 (windows 8.1) so steps may differ for your environment.

Clone blog from github:

```
git clone https://github.com/SergeyKanzhelev/apmtips.git
```

Since I use two git accounts I typically set my personal e-mail as ```user.email``` and override useHttpPath setting fro credential store so my personal github account will be used to push changed:

```
git config user.email <email>
git config credential.useHttpPath true
```

You need these to be installed:

1. Ruby. I'm using [yari](https://github.com/scottmuc/yari): yari 1.9.3
2. Python. I have SET PATH=%PATH%;C:\tools\Python27
3. "Which". I downloaded binaries from [gnuwin32](http://gnuwin32.sourceforge.net/packages/which.htm). SET PATH=%PATH%;c:\tools\which2.20\bin

(In bash: PATH=$PATH:/c/tools/.yari/ruby-1.9.3-p448-i386-mingw32/bin:/C/tools/Python27/)

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
git pull origin master
git push --set-upstream origin master
```