---
layout: post
title: "Deploy to Azure with StyleCop"
date: 2015-11-30 14:07:11 -0800
comments: true
categories: 
---
I was working on enabling continues deployment from GitHub to Azure WebApp for the sample Glimpse and Application Insights integration application. It is easy to implement this integration. Simplest way is to create "Deploy to Azure" button in your GitHub repository like I explained in [this blog post](http://blogs.msdn.com/b/webdev/archive/2015/09/16/deploy-to-azure-from-github-with-application-insights.aspx). You can also do it manually:

1. Open *Settings* blade of your web app
2. Click on *Continuous deployment*
3. Select *External Repository* and set your repository URL

Once enabled - KuDu will pull sources from repository, compile it and deploy web application.

This time it didn't work smoothly for me. I got an error:

```
MSBUILD : error : SA0001 : CoreParser : An exception occurred while parsing the 
file: System.IO.IOException, The specified registry key does not exist.. [D:\home
\site\repository\Glimpse.ApplicationInsights\Glimpse.ApplicationInsights.csproj]
Failed exitCode=1, command="D:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" 
"D:\home\site\repository\Glimpse.ApplicationInsights.Sample\
Glimpse.ApplicationInsights.Sample.csproj" /nologo /verbosity:m /t:Build 
/t:pipelinePreDeployCopyAllFilesToOneFolder /p:_PackageTempDir="D:\local\Temp\
8d2f93a7a699626";AutoParameterizationWebConfigConnectionStrings=false;
Configuration=Release;UseSharedCompilation=false 
/p:SolutionDir="D:\home\site\repository\.\\"
```

My web project doesn't have StyleCop enabled so the error was quite misleading. The good thing - this error message had original msbuild command. So I opened KuDu debug console using URL: `https://<webAppName>.scm.azurewebsites.net/DebugConsole` and typed the following command:

``` batch
cd LogFiles

"D:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" 
        "D:\home\site\repository\Glimpse.ApplicationInsights.Sample\Glimpse.ApplicationInsights.Sample.csproj" 
        /nologo 
        /verbosity:detailed 
        /t:Build 
        /t:pipelinePreDeployCopyAllFilesToOneFolder 
        /p:_PackageTempDir="D:\local\Temp\8d2f93a7a699626";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false 
        /p:SolutionDir="D:\home\site\repository\.\\" 
> buildLog.txt
```

Note, the command text is different from the original. Specifically, I changed verbosity `/verbosity:detailed` and redirected output to the file `> buildLog.txt`. Resulting error message was much easier to troubleshoot:


```
Using "StyleCopTask" task from assembly "D:\home\site\packages\StyleCop.MSBuild.4.7.49.1\build\..\tools\StyleCop.dll".
Task "StyleCopTask"
MSBUILD : error : SA0001 : CoreParser : An exception occurred while parsing the file: 
System.IO.IOException, The specified registry key does not exist.. 
[D:\home\site\repository\Glimpse.ApplicationInsights\Glimpse.ApplicationInsights.csproj]
  1 violations encountered.

Done executing task "StyleCopTask" -- FAILED.
Done building target "StyleCop" in project "Glimpse.ApplicationInsights.csproj" -- FAILED.
Done Building Project "D:\home\site\repository\Glimpse.ApplicationInsights\Glimpse.ApplicationInsights.csproj" 
        (default targets) -- FAILED.
Done executing task "MSBuild" -- FAILED.
Done building target "ResolveProjectReferences" in project 
        "Glimpse.ApplicationInsights.Sample.csproj" -- FAILED.
```

Project that my web application referencing has StyleCop enabled. Also it seems that StyleCop fail to run. 

At this point I decided that I don't need StyleCop when publishing to azure. So I've added extra condition into target import `AND ('$(_PackageTempDir)' == '')`. This condition is the best I come up with to distinguish the build for deployment from regular compilation. Here is corresponding [commit](https://github.com/Glimpse/Glimpse.ApplicationInsights/commit/d0ccba3edbf0980fe3e317d121cd2ac2216fe9bf) and full import statement: 

``` xml
<Import 
        Project="..\..\packages\StyleCop.MSBuild.4.7.49.1\build\StyleCop.MSBuild.Targets" 
        Condition="Exists('..\..\packages\StyleCop.MSBuild.4.7.49.1\build\StyleCop.MSBuild.Targets') 
                AND ('$(_PackageTempDir)' == '')" 
/>
```

So I unblocked myself, but this solutions seems hacky. I was thinking of more robust solution with setting special parameter for build using application setting `SCM_BUILD_ARGS` that will disable StyleCop. See [KuDu wiki](https://github.com/projectkudu/kudu/wiki/Configurable-settings) for details. However I wanted to get to the root cause of why StyleCop needs registry access. So I decided to troubleshoot it further.

I know there is an exception happening in StyleCop and I need its callstack. So I decided to use remote debugger to get it. First, I found github project that will run StyleCop from command line. I found one called [StyleCopCmd](https://github.com/michaelschnyder/StyleCopCmd). I downloaded and compiled it with the proper version of StyleCop.dll. I also added an extra `Console.Read` in the beggining of it so I'll have time to attach debugger. This is how I'll run it from KuDu console: 
 
```
.\StyleCopCmd.exe -s D:\home\site\repository\Glimpse.ApplicationInsights.sln -c -w
```

I followed [instructions](http://blogs.msdn.com/b/webdev/archive/2013/11/05/remote-debugging-a-window-azure-web-site-with-visual-studio-2013.aspx) to attach remote debugger to `StyleCopCmd.exe` process. There are caveats:

1. At first I used wrong credentials and was getting error like this:

  ```
  ---------------------------
  Microsoft Visual Studio
  ---------------------------
  Unable to connect to the Microsoft Visual Studio Remote Debugging Monitor named 
  'sitename.scm.azurewebsites.net'. The Microsoft Visual Studio Remote Debugging 
  Monitor (MSVSMON.EXE) does not appear to be running on the remote computer. 
  This may be because a firewall is preventing communication to the remote computer. 
  Please see Help for assistance on configuring remote debugging.
  ---------------------------
  OK   Help   
  ---------------------------
  ```

  The reason was - I used user name `$glimpse-play-ai-2` instead of fully-qualified `glimpse-play-ai-2\$glimpse-play-ai-2`. You may have the same message with the completely wrong credentials. 
        
2. When I run *Attach to the process* from Visual Studio I haven't seen the process `StyleCopCmd.exe`. The reason is that this process is SCM (KuDu) process and I needed to specify "sitename.**scm**.azurewebsites.net" as a Qulifier, not "sitename.azurewebsites.net" in *Attach to the Process* dialog.   
3. When debugging external code in Visual Studio - make sure to uncheck the box "Just My Code" in debugger options.           

I set Visual Studio to stop on every CLR exception and let `StyleCopCmd.exe` run. It paused on excpetion with the following call stack:

```
mscorlib.dll!Microsoft.Win32.RegistryKey.Win32Error(int errorCode, string str) Line 1694        C#
mscorlib.dll!Microsoft.Win32.RegistryKey.CreateSubKeyInternal(string subkey, Microsoft.Win32.RegistryKeyPermissionCheck permissionCheck, object registrySecurityObj, Microsoft.Win32.RegistryOptions registryOptions) Line 409        C#
mscorlib.dll!Microsoft.Win32.RegistryKey.CreateSubKey(string subkey, Microsoft.Win32.RegistryKeyPermissionCheck permissionCheck) Line 297        C#
mscorlib.dll!Microsoft.Win32.RegistryKey.CreateSubKey(string subkey) Line 289        C#
StyleCop.dll!StyleCop.RegistryUtils.CurrentUserRoot.get()        Unknown
StyleCop.dll!StyleCop.RegistryUtils.CUGetValue(string name)        Unknown
StyleCop.dll!StyleCop.StyleCopCore.GetLastUpdateCheckDate()        Unknown
StyleCop.dll!StyleCop.StyleCopCore.CheckForStyleCopUpdate(StyleCop.CodeProject project)        Unknown
StyleCop.dll!StyleCop.StyleCopCore.InitializeProjectForAnalysis(StyleCop.CodeProject project, StyleCop.StyleCopThread.Data data, StyleCop.ResultsCache cache)        Unknown
StyleCop.dll!StyleCop.StyleCopCore.Analyze(System.Collections.Generic.IList<StyleCop.CodeProject> projects, bool ignoreCache, string settingsPath)        Unknown
StyleCop.dll!StyleCop.StyleCopCore.FullAnalyze(System.Collections.Generic.IList<StyleCop.CodeProject> projects)        Unknown
StyleCop.dll!StyleCop.StyleCopConsole.Start(System.Collections.Generic.IList<StyleCop.CodeProject> projects, bool fullAnalyze)        Unknown
StyleCopCmd.exe!StyleCopCmd.Core.StyleCopExecutor.Run() Line 70        C#
StyleCopCmd.exe!StyleCopCmd.Program.Main(string[] args) Line 61        C#
```

Using disassembler I found that StyleCop tries to set registry key when checks for the latest version:
 
```
 Registry.CurrentUser.CreateSubKey("Software\\CodePlex\\StyleCop")
```

So I’ve added this flag to StyleCop settings file to disable this version check. Here is the [commit](https://github.com/Glimpse/Glimpse.ApplicationInsights/commit/ccb9b90d5cf02273a75edffabb1145125e36632d): 

``` xml
<BooleanProperty Name="AutoCheckForUpdate">False</BooleanProperty>
```

And it solved the issue.

Azure Web App infrastructure gives you great flexibility and power deploying and running your web applications. Even though it's infrastructure has some limitations - it is really easy to troubleshoot issues with all the tools it provides.  