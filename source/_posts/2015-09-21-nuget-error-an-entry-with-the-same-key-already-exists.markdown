---
layout: post
title: "Nuget error: An entry with the same key already exists"
date: 2015-09-21 21:23:40 -0700
comments: true
categories: 
- Application Insights
- Troubleshooting
---
Sometimes installing the NuGet you can see the error message ```An entry with the same key already exists```:
  
```
PM> Install-Package "Microsoft.ApplicationInsights.DependencyCallstacks" -Source "https://www.myget.org/F/applicationinsights-sdk-labs/" -Pre
Attempting to gather dependencies information for package 'Microsoft.ApplicationInsights.DependencyCallstacks.0.20.0-build14383' with respect to project 'WebApplication3', targeting '.NETFramework,Version=v4.5.2'
Attempting to resolve dependencies for package 'Microsoft.ApplicationInsights.DependencyCallstacks.0.20.0-build14383' with DependencyBehavior 'Lowest'
Install-Package : An entry with the same key already exists.
At line:1 char:1
+ Install-Package "Microsoft.ApplicationInsights.DependencyCallstacks"  ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Install-Package], Exception
    + FullyQualifiedErrorId : NuGetCmdletUnhandledException,NuGet.PackageManagement.PowerShellCmdlets.InstallPackageCommand
```

Changine the order of installing NuGets sometimes helped so I never tried to troubleshoot it further. Also I found this [forum post](https://social.msdn.microsoft.com/Forums/en-US/b2f113a9-eeef-44d4-b9fe-d7aa98295d99/cant-install-nuget-package-in-vs2015?forum=AzureKeyVault&prof=required) so I figured it maybe some generic problem.

Yesterday I got this error again. It took me 10 minutes to troubleshoot it. Simple steps:

- Open windbg (32-bit) and attach to ```devenv.exe```
- Make it stop on managed exceptions: ```sxe clr``` 
- Load ```sos``` using command ```loadby sos clr```

Then I printed stack:

```
0:061> !clrstack
OS Thread Id: 0x3da8 (61)
Child SP       IP Call Site
29abc3e0 76ca3e28 [HelperMethodFrame: 29abc3e0] 
29abc490 727b7d91 System.ThrowHelper.ThrowArgumentException(System.ExceptionResource) [f:\dd\NDP\fx\src\compmod\system\collections\generic\throwhelper.cs @ 63]
29abc4a0 729ef49a System.Collections.Generic.TreeSet`1[[System.Collections.Generic.KeyValuePair`2[[System.__Canon, mscorlib],[System.__Canon, mscorlib]], mscorlib]].AddIfNotPresent(System.Collections.Generic.KeyValuePair`2) [f:\dd\NDP\fx\src\compmod\system\collections\generic\sorteddictionary.cs @ 803]
29abc4b0 723b6149 System.Collections.Generic.SortedDictionary`2[[System.__Canon, mscorlib],[System.__Canon, mscorlib]].Add(System.__Canon, System.__Canon) [f:\dd\NDP\fx\src\compmod\system\collections\generic\sorteddictionary.cs @ 167]
29abc4c4 17277f3b NuGet.Resolver.ResolverPackage..ctor(System.String, NuGet.Versioning.NuGetVersion, System.Collections.Generic.IEnumerable`1, Boolean, Boolean)
29abc578 069d15a4 NuGet.Resolver.PackageResolver.Resolve(NuGet.Resolver.PackageResolverContext, System.Threading.CancellationToken)
```

It's easy to look at sources as NuGet is open source. Here is line of [code](https://github.com/NuGet/NuGet3/blob/0002affc8087784a18f8ed735c3ce7620e84b267/src/NuGet.Resolver/PackageResolver.cs#L62) that fails. We pass list of dependencies to the constructor of ```ResolverPackage```:
 
``` csharp
resolverPackages.Add(new ResolverPackage(package.Id, package.Version, dependencies, package.Listed, false));
```

and it in turns [add all dependencies](https://github.com/NuGet/NuGet3/blob/dde7ebfc7e8e9c5b4fee492152f7c54db789643f/src/NuGet.Resolver/ResolverPackage.cs#L47) into collection:	 
 
``` csharp
_dependencyIds.Add(dependency.Id, dependency.VersionRange == null ? VersionRange.All : dependency.VersionRange);
```

So I took all objects on the stack using ```!dso``` and found the array of dependencies there. You can see that is consist of 22 dependencies and two of them: ```249c9338``` and ```249c93b8``` have the same name:

```
0:061> !DumpArray /d 249ca23c
Name:        NuGet.Packaging.Core.PackageDependency[]
MethodTable: 1ecba294
EEClass:     72ce3750
Size:        100(0x64) bytes
Array:       Rank 1, Number of elements 22, Type CLASS
Element Methodtable: 1ecb9d24
[0] 249c9338
[1] 249c9378
[2] 249c93b8
[3] 249c9448
[4] 249c94d8
[5] 249c9568
[6] 249c9604
[7] 249c9694
[8] 249c9724
[9] 249c97b4
[10] 249c9844
[11] 249c98d4
[12] 249c9964
[13] 1d2e5a70
[14] 1d2e5b00
[15] 1d2e5b90
[16] 1d2e5c20
[17] 1d2e5cb0
[18] 1d2e5d40
[19] 1d2e5dd0
[20] 249ca19c
[21] 249ca22c

0:061> !DumpObj /d 249c9338
Name:        NuGet.Packaging.Core.PackageDependency
MethodTable: 1ecb9d24
EEClass:     1ec961e8
Size:        16(0x10) bytes
File:        C:\PROGRAM FILES (X86)\MICROSOFT VISUAL STUDIO 14.0\COMMON7\IDE\EXTENSIONS\Q04IPECQ.ZWQ\NuGet.Packaging.Core.Types.dll
Fields:
      MT    Field   Offset                 Type VT     Attr    Value Name
73101d7c  4000008        4        System.String  0 instance 1d2dc7f4 _id
11b5bd88  4000009        8 ...ning.VersionRange  0 instance 1d2fdfa8 _versionRange

0:061> !DumpObj /d 1d2dc7f4
Name:        System.String
MethodTable: 73101d7c
EEClass:     72ce3620
Size:        52(0x34) bytes
File:        C:\WINDOWS\Microsoft.Net\assembly\GAC_32\mscorlib\v4.0_4.0.0.0__b77a5c561934e089\mscorlib.dll
String:      Microsoft.Bcl.Async
Fields:
      MT    Field   Offset                 Type VT     Attr    Value Name
73103cc4  4000243        4         System.Int32  1 instance       19 m_stringLength
731027c0  4000244        8          System.Char  1 instance       4d m_firstChar
73101d7c  4000248       40        System.String  0   shared   static Empty
    >> Domain:Value  0112e5a8:NotInit  <<
		
0:061> !DumpObj /d 249c93b8
Name:        NuGet.Packaging.Core.PackageDependency
MethodTable: 1ecb9d24
EEClass:     1ec961e8
Size:        16(0x10) bytes
File:        C:\PROGRAM FILES (X86)\MICROSOFT VISUAL STUDIO 14.0\COMMON7\IDE\EXTENSIONS\Q04IPECQ.ZWQ\NuGet.Packaging.Core.Types.dll
Fields:
      MT    Field   Offset                 Type VT     Attr    Value Name
73101d7c  4000008        4        System.String  0 instance 1d2dc8d0 _id
11b5bd88  4000009        8 ...ning.VersionRange  0 instance 1d2fdfe0 _versionRange

0:061> !DumpObj /d 1d2dc8d0
Name:        System.String
MethodTable: 73101d7c
EEClass:     72ce3620
Size:        52(0x34) bytes
File:        C:\WINDOWS\Microsoft.Net\assembly\GAC_32\mscorlib\v4.0_4.0.0.0__b77a5c561934e089\mscorlib.dll
String:      Microsoft.Bcl.Async
Fields:
      MT    Field   Offset                 Type VT     Attr    Value Name
73103cc4  4000243        4         System.Int32  1 instance       19 m_stringLength
731027c0  4000244        8          System.Char  1 instance       4d m_firstChar
73101d7c  4000248       40        System.String  0   shared   static Empty
    >> Domain:Value  0112e5a8:NotInit  <<
```
 
Looking at nuspec you can see that ```Microsoft.Bcl.Async``` is a dependency for both platforms - Framework 4.0 and Windows 8:

``` xml
<group targetFramework=".NETFramework4.0">
<dependency id="Microsoft.Bcl.Async" version="1.0.168" />
<dependency id="Microsoft.Diagnostics.Tracing.EventSource.Redist" version="1.1.24" />
</group>
<group targetFramework=".NETFramework4.5" />
<group targetFramework="WindowsPhone8.0">
<dependency id="Microsoft.Bcl.Async" version="1.0.168" />
</group>
```

So it seems that NuGet do not distinguish dependencies for the different plaforms while building the list of references. So I filed the issue at [GitHub](https://github.com/NuGet/Home/issues/1412) and hope it will be resolved soon.

Workaround is simple if the list od dependencies for the platform is small. Just add ```-DependencyVersion Ignore``` when calling ```Install-Package```. You'll need to install all dependencies manually.

When everything is open source it is very easy to troubleshoot issues. So we open sourcing more code of Application Insights SDK. Now it is server telemetry channel. See this [PR](https://github.com/Microsoft/ApplicationInsights-dotnet/pull/41).  
