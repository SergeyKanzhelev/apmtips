---
layout: post
title: "Application Versioning: semantic or automatic?"
date: 2015-06-18 09:36:35 -0700
comments: true
categories:
- Versioning
---
Looking at [@pksorensen](https://twitter.com/pksorensen)'s example of OWIN middleware to [monitor server request]( https://gist.github.com/s093294/d4b8abdaf4000b6c7f80) I noticed this [line](https://gist.github.com/s093294/d4b8abdaf4000b6c7f80#file-applicationinsightrequesttrackingmiddleware-cs-L27) of code:

``` csharp
rt.Context.Component.Version = "1.0.0";
```

It will set application version for telemetry items so you can group telemetry by version and understand in which version of application certain exception happened.

**Note:** *Yes, it is confusing name. SDK refers to application as "Component" when in [UI](http://portal.azure.com) it is called "Application".*

This code snippet uses constant string as an application version. My guess is that this version represent semantic version of API call. If you versioned your REST API using urls like this: ```https://management.azure.com/subscriptions?api-version=2014-04-01-preview``` you'd probably need to change your middleware to read version from ```api-version``` query string parameter.

Semantic version is good for certain telemetry reports. For instance you can see how much traffic goes to which version of API to decide when to shut down older version. However semantic version is something you need to code explicitly - there is no generic way to version applications and APIs.

So instead of using semantic version - we suggest to use automatically generated version number. For instance, [this article](http://blogs.msdn.com/b/visualstudioalm/archive/2015/01/07/application-insights-support-for-multiple-environments-stamps-and-app-versions.aspx
) suggest to use Assembly version of your application as application version.

You'll need to use wildcard in ```Assembly.cs```:

``` csharp
[assembly: AssemblyVersion("1.0.*")]
```

and use telemetry initializer to initialize application version:

``` csharp
telemetry.Context.Component.Version =
    typeof(TestBuildInfo).Assembly.GetName().Version.ToString();
```

Now all telemetry items will be marked with the version like ```1.0.5647.32696```, where ```5647``` and ```32696``` are some semi-random numbers.

Drawback of this approach is that again, you need to write some code. Furthermore, there is no way to detect which assembly is a *"main"* assembly of an application. So your telemetry initializer should be application specific.

This brings us to the reason I write this blog post. Visual Studio has a feature that I believe undeservedly is not well known and widely used. It is called build information file or ```BuildInfo.config```.

Turing this feature on is simple. Just add a property to your project file:

``` xml
<PropertyGroup>
  <GenerateBuildInfoConfigFile>true</GenerateBuildInfoConfigFile>
</PropertyGroup>
```

This will generate the file ```bin/$(ProjectName).BuildInfo.config``` when you compile locally with the commit number and auto-generated build label and ```BuildInfo.config``` when you publish your application. For instance, once I enabled continues integration in Visual Studio online this file is placed next to ```web.config```:

``` xml
<?xml version="1.0" encoding="utf-8"?>
<DeploymentEvent xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/VisualStudio/DeploymentEvent/2013/06">
  <ProjectName>TestBuildInfo</ProjectName>
  <SourceControl type="Git">
    <GitSourceControl xmlns="http://schemas.microsoft.com/visualstudio/deploymentevent_git/2013/09">
      <RepositoryUrl>/DefaultCollection/temp/_git/temp</RepositoryUrl>
      <ProjectPath>/TestBuildInfo/TestBuildInfo.csproj</ProjectPath>
      <BuiltSolution>/TestBuildInfo.sln</BuiltSolution>
      <CommitId>fbbaf40f804ad2646d5ce70b545fd9fd257feca8</CommitId>
      <ShortCommitId>fbbaf40</ShortCommitId>
      <CommitDateUTC>Thu, 18 Jun 2015 17:07:56 GMT</CommitDateUTC>
      <CommitComment>initial commit</CommitComment>
      <CommitAuthor>Sergey Kanzhelev</CommitAuthor>
    </GitSourceControl>
  </SourceControl>
  <Build type="TeamBuild">
    <MSBuild>
      <BuildDefinition kind="informative, summary">TestBuildInfoApp_CD</BuildDefinition>
      <BuildLabel kind="label">TestBuildInfoApp_CD_20150618.1</BuildLabel>
      <BuildId kind="id">e6e457a1-debf-4bda-b0c9-61344fd55ae2,vstfs:///Build/Build/37</BuildId>
      <BuildTimestamp kind="informative, summary">Thu, 18 Jun 2015 18:08:19 GMT</BuildTimestamp>
      <Configuration kind="informative">Debug</Configuration>
      <Platform kind="informative">AnyCPU</Platform>
      <BuiltSolution>/TestBuildInfo.sln</BuiltSolution>
    </MSBuild>
  </Build>
</DeploymentEvent>
```

It is great to have this file published with your application as you will always know which version of source code it was built from.

Application Insights Web SDK will install context initializer called  ```BuildInfoConfigComponentVersionContextInitializer``` that will read this file and mark telemetry items with the application version equal to ```BuildLabel``` from the file above. In this example it will be ```TestBuildInfoApp_CD_20150618.1```. Now, looking at your telemetry you can always find the build that produced this binary.

Here are some [additional details](http://blogs.msdn.com/b/visualstudioalm/archive/2013/11/15/implementing-deployment-markers-in-application-insights.aspx) on how this feature used to work in the old version of Application Insights. From this article you can find that you can use ```IncludeServerNameInBuildInfo``` property to enrich ```BuildInfo.config``` even more and how to configure copying of this file next to ```web.config``` while developing. Do not forget to ```.gitignore``` it though...
