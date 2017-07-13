---
layout: post
title: "Find application by it's instrumentation key"
date: 2017-07-12 23:23:57 -0700
comments: true
categories: DYI
---
Meant to show how to use the new [Azure Cloud Shell](https://azure.microsoft.com/features/cloud-shell). Unfortunately two scenarios I wanted to use it for are not that easy to implement. If you have time - go comment and upvote these two issues: [azure-cli#3457](https://github.com/Azure/azure-cli/issues/3457) and [azure-cli#3641](https://github.com/Azure/azure-cli/issues/3641).

Here is how you can find out the name of the application given its instrumentation key. This situation is not that rare. Especially if you have access to quite a few subscriptions and monitor many services deployed to different environments and regions. You have an instrumentation key in configuration file, but not sure where to search for telemetry.

**First** got to Azure Cloud Shell. It gives you bash and allows you to access all your azure resources.

**Second** create a file `findApplicationByIkey.sh` with the following content:

``` bash
#!/bin/bash

if [ -z "$ikeyToFind" ]; then
    echo "specify the instrumentaiton key"
    exit
fi
echo "search for instrumentation key $1"
ikeyToFind=$1

# this function search for the instrumentation key in a given subscription
function findIKeyInSubscription {
  echo "Switch to subscription $1"
  az account set --subscription $1

  # list all the Application Insights resources.
  # for each of them take an instrumentation key 
  # and compare with one you looking for
  az resource list \
    --namespace microsoft.insights --resource-type components --query [*].[id] --out tsv \
      | while \
          read ID; \
          do  printf "$ID " && \
              az resource show --id "$ID" --query properties.InstrumentationKey --o tsv; \
        done \
      | grep "$ikeyToFind"
}

# run the search in every subscription...
az account list --query [*].[id] --out tsv \
    | while read OUT; do findIKeyInSubscription $OUT; done
```

**Finally**, run it: `./findApplicationByIkey.sh ce85cf15-de20-49bb-83d7-234b5116623b`

```
sergey@Azure:~/Sergey$ ./findApplicationByIkey.sh ce85cf15-de20-49bb-83d7-234b5116623b
search for instrumentation key ce85cf15-de20-49bb-83d7-234b5116623b
A few accounts are skipped as they don't have 'Enabled' state. Use '--all' to display them.
Switch to subscription 5fb94e1c-7bbf-4ab8-9c51-5dda40adc12e
Switch to subscription 52f57f24-51d5-479f-a532-facd9ee907a6
Switch to subscription eec57090-02b8-48f2-b78e-a38b7a53e1ab
/subscriptions/c3becfa8-419b-4b30-b08b-a2865ace64bf/resourceGroups/MY-RG/providers/
microsoft.insights/components/test-ai-app ce85cf15-de20-49bb-83d7-234b5116623b
Switch to subscription a8308a0b-9ee1-4548-9bbf-2b1d670e0767
The client 'Sergey@' with object id '03aa4cb5-650f-45bf-8d45-474664262685' does not have 
authorization to perform action 'Microsoft.Resources/subscriptions/resources/read' over 
scope '/subscriptions/edfd8475-8c5f-45c3-b533-a5132e8f9ada'.
Switch to subscription d6043348-75b2-41cd-ba7e-e1d317619002
...
...
```

The answer is: `/subscriptions/c3becfa8-419b-4b30-b08b-a2865ace64bf/resourceGroups/MY-RG/providers/microsoft.insights/components/test-ai-app` Better than guessing.