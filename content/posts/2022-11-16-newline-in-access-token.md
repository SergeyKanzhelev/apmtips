---
layout: post
title: "Kubernetes secrets, base64, and newline"
date: 2022-11-17 00:48:38 +00:00
comments: true
categories:
---

When creating a k8s secret manually, using command like this you need to provide `base64` encoded secret. Never forget to use `-w 0` when encoding the string.

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github
type: Opaque
data:
  access_token: ACCESS_TOKEN
EOF
```

Recently I forgot the `-w 0` in `base64` command and spent too much time troubleshooting it. It seems to be a common issue:
https://superuser.com/questions/1225134/why-does-the-base64-of-a-string-contain-n

Yes, I logged the access token from the app to validate it. I used `%v` qualifier to do it and access token was the last argument. Looking back I should have used `%q` instead or have it in the middle of the log string. But I didn't. So I resolved it a hard way.

I ended up logging the headers of http requests. Here is how I did it.

First, implement the logging round tripper:

```
// This type implements the http.RoundTripper interface
type LoggingRoundTripper struct {
	Proxy http.RoundTripper
}

func (lrt LoggingRoundTripper) RoundTrip(req *http.Request) (res *http.Response, e error) {
	fmt.Printf("Sending request to: %v\n", req.URL)
	fmt.Printf("With headers: %+v\n", req.Header)

	return lrt.Proxy.RoundTrip(req)
}
```

Then use the http client configured with the above round tripper with `oauth2` client:

```
// Use the custom HTTP client when requesting a token.
httpClient := &http.Client{
  Transport: LoggingRoundTripper{http.DefaultTransport},
}

ctx := context.Background()

ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)

ts := oauth2.StaticTokenSource(
  &oauth2.Token{AccessToken: access_token},
)
tc := oauth2.NewClient(ctx, ts)

client := github.NewClient(tc)
```

Interestingly, the fact that this is working may not be aligned with the documentation: https://pkg.go.dev/golang.org/x/oauth2#NewClient. Docs says:

> Note that if a custom *http.Client is provided via the Context it is used only for token acquisition and is not used to configure the *http.Client returned from NewClient.

Apparently it is already reported: https://github.com/golang/oauth2/issues/324. Maybe this post will be irrelevant soon. But it is working now.
