![Midiex](assets/req_ga_logo_wide.png)

[![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/req_ga)
[![Package](https://img.shields.io/hexpm/v/req_ga.svg)](https://hex.pm/packages/req_ga)

# ReqGA

## About
ReqGA is a minimal [Req](https://hex.pm/packages/req) plugin for [Google Google Analytics 4](https://developers.google.com/analytics/devguides/collection/ga4) (GA4).

### Status
This is an *early draft* and currently under development.

### What is Req?
Req is an excellent, ergonomic and extensibile HTTP client for Elixir. It allows custom request and response steps, which ReqGA uses to interact with Google Analytics API endpoints.

You can learn more about Req by visiting:
- https://hexdocs.pm/req/readme.html
- https://github.com/wojtekmach/req

### Google Analytics APIs
This library is for use with the newer GA4 APIs. It can be used with both the [Data API](https://developers.google.com/analytics/devguides/reporting/data/v1) and the [Admin API](https://developers.google.com/analytics/devguides/config/admin/v1) although only some API methods have been implemented.

## Authenticating to Google Cloud
[Goth](https://hex.pm/packages/goth) is used for authentication.

This requires setting up a service account in Google Cloud and and a adding it to the Google Analytics 4 properties you wish to interact with.

For more information on this, visit:
- https://developers.google.com/analytics/devguides/reporting/data/v1/quickstart-client-libraries
- https://developers.google.com/analytics/devguides/config/admin/v1/quickstart-client-libraries
- https://cloud.google.com/iam/docs/service-account-overview

## Tabular data
Some of the Structs implement the `Table.Reader` protocol (https://hex.pm/packages/table) and can be traversed by rows or columns.

This makes it easier to view in LiveBook as a table by piping it to [`Kino.DataTable.new/2`](https://hexdocs.pm/kino/Kino.DataTable.html#new/2) or for creating a DataFrame with [`Explorer.DataFrame.new/2`](https://hexdocs.pm/explorer/Explorer.DataFrame.html#new/2).


## Related packages
You may also be interested with the [ReqBigQuery](https://hex.pm/packages/req_bigquery) which is a Req plugin for [BigQuery](https://cloud.google.com/bigquery).

## Example
```
# Authenticate with Google Cloud using Goth with the desired API scopes

iex> credentials = "credentials.json" |> File.read!() |> Jason.decode!()

iex> scopes = [
  "https://www.googleapis.com/auth/analytics",
  "https://www.googleapis.com/auth/analytics.edit",
  "https://www.googleapis.com/auth/analytics.readonly",
  "https://www.googleapis.com/auth/analytics.manage.users",
  "https://www.googleapis.com/auth/analytics.manage.users.readonly"
]

iex> source = {:service_account, credentials, [scopes: scopes]}
iex> {:ok, _} = Goth.start_link(name: GA, source: source, http_client: &Req.request/1)

# Attach ReqGA to Req's request and response steps 
iex> req = Req.new() |> ReqGA.attach(goth: GA)

# Query away!

# ID of property to query. In the format "properties/<id number>", e.g.:
iex> property_id = "properties/264264328"

# Define a report to be posted
iex> report = %{
    "dateRanges" => [%{ "startDate" => "2023-09-01", "endDate" => "2023-09-15" }],
    "dimensions" =>[%{ "name" => "country" }],
    "metrics" => [
      %{"name" => "activeUsers"},
      %{"name" => "userEngagementDuration"},
      %{"name" => "engagementRate"},
      %{"name" => "organicGoogleSearchClickThroughRate"},
    ]
  }

# Run the report with the :run_report method
iex> res = Req.post!(req, ga: :run_report, property_id: property_id, json: report)

# The response body will hold the decoded data
iex> res.body
%ReqGA.ReportResponse{
  dimensions: ["country"],
  metrics: [
    {"activeUsers", "TYPE_INTEGER"},
    {"userEngagementDuration", "TYPE_SECONDS"},
    {"engagementRate", "TYPE_FLOAT"},
    {"organicGoogleSearchClickThroughRate", "TYPE_FLOAT"}
  ],
  columns: ["country", "activeUsers", "userEngagementDuration", "engagementRate",
  "organicGoogleSearchClickThroughRate"],
  rows: [
    ["Australia", 10089, 568807, 0.6080890737138641, 0.06607765656247402],
    ["India", 46, 1022, 0.6730769230769231, 0.006472491909385114]
  ],
  totals: nil,
  maximums: nil,
  minimums: nil,
  count: 2,
  property_quota: nil,
  metadata: %{
    "currencyCode" => "AUD",
    "subjectToThresholding" => true,
    "timeZone" => "Australia/Melbourne"
  }
}
```

## Installation

### Adding it to your Elixir project 
The package can be installed by adding `req_ga` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:req_ga, "~> 0.1.0"}
  ]
end
```

### Using within LiveBook and IEx
```elixir
Mix.install([{:req_ga, "~> 0.1.0"}])
```

## LiveBook demonstration
Also see the demo in LiveBook at [/livebook/req_ga_demo.livemd.livemd](/livebook/req_ga_demo.livemd).

## Documentation
The docs can be found at <https://hexdocs.pm/req_ga>.

