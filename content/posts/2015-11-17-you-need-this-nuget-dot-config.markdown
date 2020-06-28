---
layout: post
title: "You need this nuget.config"
date: 2015-11-17 09:01:42 -0800
comments: true
aliases: [/blog/2015-11-17-you-need-this-nuget-dot-config/]
categories:
- random 
---
Suddenly many projects on my computer stoped compiling - they cannot find NuGet dependencies. After short digging I found that my default ```NuGet.config``` file ```%APPDATA%\NuGet\NuGet.Config``` was changed. Now it sets packages folder to be ```..\..\..\Users\sergkanz\AppData\Roaming\packages```. To be absolutely precise the packages folder is set to  ```%APPDATA%\NuGet\..\packages```, but Visual Studio will expand the path.
 
I'm not sure when and how I changed this file. Maybe it is a feature of new NuGet version? Anyway it turns out to be a very good thing. I see two benefits here:

- For the test projects I share packages and never even copy them from cache. I just point my test projects directly to the cache folder
- Any project that I share with other people now requires it's own ```NuGet.config``` file. And I forced to create it - no way anybody will have the folder ```..\..\..\Users\sergkanz\AppData\Roaming\packages```.   

Having personalized ```NuGet.config``` for the shared project is a good idea. First, you can configure the same packages folder for multiple solutions in one repo. Second, you also set the list of extra package sources you are using and some [other settings](http://docs.nuget.org/consume/nuget-config-file).

Here is a small ```NuGet.config``` that I copy now to the test projects that I want to share with others. Just place it to the solution folder and it will replicate the default ```$(SolutionDir)\packages``` behavior:

``` xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <config>
    <add key="repositoryPath" value=".\packages" />
  </config>
  <packageSources>
    <add key="nuget.org" value="https://www.nuget.org/api/v2/" />
  </packageSources>
</configuration>
```

Sometimes you need to restart Visual Studio so solution will pick up this configuration. 