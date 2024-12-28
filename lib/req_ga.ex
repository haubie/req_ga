defmodule ReqGA do
  @moduledoc """
  A Req plugin for interacting with Google Analytics 4 APIs.

  ## Currently implemented methods
  | :ga API method            | API       | Endpoint                  | Req HTTP method supported |
  | ------------------------- | --------- | ------------------------- | ------------------------- |
  | :run_report               | Data API  | ":runReport"              | post                      |
  | :batch_run_reports        | Data API  | ":batchRunReports"        | post                      |
  | :run_pivot_report         | Data API  | ":runPivotReport"         | post                      |
  | :batch_run_pivot_reports  | Data API  | ":batchRunPivotReports"   | post                      |
  | :run_realtime_report      | Data API  | ":runRealtimeReport"      | post                      |
  | :check_compatibility      | Data API  | ":checkCompatibility"     | post                      |
  | :metadata                 | Data API  | "/metadata"               | get                       |
  | :audience_lists           | Data API  | "/audienceLists"           | get                       |
  | :audience_exports         | Data API  | "/audienceExports"        | get                       |
  | :account_summaries        | Admin API | "/accountSummaries"       | get                       |
  | :custom_dimensions        | Admin API | "/customDimensions"       | get, post                 |
  | :custom_metrics           | Admin API | "/customMetrics"          | get, post                 |
  | :accounts                 | Admin API | "/accounts"               | get, delete, post         |
  | :properties               | Admin API | "/accounts"               | get, delete, post         |
  | :key_events               | Admin API | "/keyEvents"              | get                       |

  ## Example usage
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
  ## Use with Table
  Some of the Structs implement the `Table.Reader` protocol (https://hex.pm/packages/table) and can be traversed by rows or columns.
  - ReqGA.ReportResponse
  - ReqGA.PivotReportResponse
  - ReqGA.AccountList
  - ReqGA.Account

  This makes it easier to view in LiveBook as a table by piping it to `Kino.DataTable.new` or for creating a DataFrame with `Explorer.DataFrame.new`.

  ## API methods
  Below are the  API methods from the Google Analytics Data API which have been implemented in this library.

  The method is passed to Req using the `:ga` parameter. For example, the `:run_report` API method would be called as follows:
  ```
  res = Req.post!(req, ga: :run_report, property_id: "properties/264264328", json: report)
  ```

  ### :run_report
  Returns a customized report of your Google Analytics data.

  This is equivalent of the Google Analytics Data API endpoint: `POST /v1beta/{property=properties/*}:runReport`

  Use `Req.post` or `Req.post!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"
  - `json: report` where report is a map representing a [JSON report](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runReport)

  #### Example
  ```
  report = %{
        "dateRanges" => [%{ "startDate" => "2023-09-01", "endDate" => "2023-09-15" }],
        "dimensions" =>[%{ "name" => "country" }],
        "metrics" => [
          %{"name" => "activeUsers"},
          %{"name" => "userEngagementDuration"},
          %{"name" => "engagementRate"},
          %{"name" => "organicGoogleSearchClickThroughRate"},
        ]
      }

  res = Req.post!(req, ga: :run_report, property_id: "properties/264264328", json: report)
  ```

  #### More information:
  - https://developers.google.com/analytics/devguides/reporting/data/v1/basics
  - https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runReport

  ### :batch_run_reports
  Returns multiple reports in a batch.

  This is equivalent of the Google Analytics Data API endpoint: `POST /v1beta/{property=properties/*}:batchRunReports`

  Use `Req.post` or `Req.post!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"
  - `json: batch_report` where batch_report is a map representing a [JSON batch report request](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/batchRunReports)

  ### :run_pivot_report
  Returns a customized pivot report of your Google Analytics event data.

  This is equivalent of the Google Analytics Data API endpoint: `POST /v1beta/{property=properties/*}:runPivotReport`

  Use `Req.post` or `Req.post!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"
  - `json: pivot_report_request` where pivot_report_request is a map representing a [JSON pivot report request](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runPivotReport)

  ### batch_run_pivot_reports
  Returns multiple pivot reports in a batch. All reports must be for the same GA4 Property.

  This is equivalent of the Google Analytics Data API endpoint: `POST https://analyticsdata.googleapis.com/v1beta/{property=properties/*}:batchRunPivotReports`

  Use `Req.post` or `Req.post!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"
  - `json: batch_pivot_report_request` where batch_pivot_report_request is a map representing a [JSON batch pivot report request](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/batchRunPivotReports)


  ### :run_realtime_report
  Returns a customized report of realtime event data for your property.

  This is equivalent of the Google Analytics Data API endpoint: `POST /v1beta/{property=properties/*}:runRealtimeReport`

  Use `Req.post` or `Req.post!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"
  - `json: realtime_report_request` where realtime_report_request is a map representing a [JSON realtime report request](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runRealtimeReport)

  ### :check_compatibility
  This compatibility method lists dimensions and metrics that can be added to a report request and maintain compatibility.

  This is equivalent of the Google Analytics Data API endpoint: `POST /v1beta/{property=properties/*}:checkCompatibility`

  Use `Req.post` or `Req.post!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"
  - `json: compatibility_request` where compatibility_request is a map representing a [JSON compatibility request](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/checkCompatibility)

  ### :metadata
  Returns metadata for dimensions and metrics available in reporting methods.

  This is equivalent of the Google Analytics Data API endpoint: `GET /v1beta/{name=properties/*/metadata}`

  Use `Req.get` or `Req.get!` with the following parameters:
  - `property_id:` an ID of the GA4 property in the format "properties/264264328"

  """

  @allowed_options ~w(goth ga property_id account_id show_deleted auto_page)a

  @base_admin_url "https://analyticsadmin.googleapis.com/v1beta"
  @base_data_url "https://analyticsdata.googleapis.com/v1beta"
  @base_data_alpha_url "https://analyticsdata.googleapis.com/v1alpha"

  @ga_enpoints [
    run_report: "runReport",
    batch_run_reports: "batchRunReports",
    run_pivot_report: "runPivotReport",
    batch_run_pivot_reports: "batchRunPivotReports",
    run_realtime_report: "runRealtimeReport",
    metadata: "metadata",
    check_compatibility: "checkCompatibility",
    audience_list: "/audienceList",
    audience_exports: "audienceExports",
    account_summaries: "accountSummaries",
    custom_dimensions: "customDimensions",
    custom_metrics: "customMetrics",
    accounts: "accounts",
    properties: "properties",
    key_events: "keyEvents"
  ]

  alias ReqGA.Property
  alias Req.Request
  alias ReqGA.{Account, AccountList, ReportResponse, PivotReportResponse}

  @doc """
  Attaches ReqGA to Req's request and response steps.

  ## Example
  Assuming a Goth process was started with the name `GA`:
  ```
  req = Req.new() |> ReqGA.attach(goth: GA)
  ```
  """
  def attach(%Request{} = request, options \\ []) do
    request
    |> Request.prepend_request_steps(ga_run: &run/1)
    |> Request.register_options(@allowed_options)
    |> Request.merge_options(options)
  end

  ## -------------------
  ## Run the request
  ## -------------------
  defp run(%Request{options: options} = request) do
    token = get_token(options)
    uri = uri_for(options)

    %{request | url: uri}
    |> Request.merge_options(auth: {:bearer, token})
    |> Request.append_response_steps(ga_decode: &decode/1)
  end

  defp run(%Request{} = request) do
    request
  end

  ## -------------------
  ## Decode responses
  ## -------------------
  defp decode({request, %{status: 200} = response}) do
    {request, update_in(response.body, &decode_body(&1, request))}
  end

  defp decode(any), do: any

  # For properties (via Admin API)
  defp recursive_decode_body(body, request, acc \\ [])

  defp recursive_decode_body(
         %{"properties" => properties, "nextPageToken" => next_page} = _body,
         request,
         acc
       ) do
    process_current_page = ReqGA.PropertyList.new(properties, next_page)

    next_page_body =
      request
      |> Req.merge(params: [pageToken: next_page])
      |> then(fn r -> Req.merge(r, url: %{r.url | query: URI.encode_query(r.options.params)}) end)
      |> Req.get!()
      |> then(fn r -> r.body end)

    recursive_decode_body(next_page_body, request, acc ++ [process_current_page])
  end

  defp recursive_decode_body(%{"properties" => properties} = _body, _request, acc) do
    all_pages = acc ++ [ReqGA.PropertyList.new(properties)]
    props = Enum.flat_map(all_pages, & &1.properties)
    %ReqGA.PropertyList{properties: props, count: length(props)}
  end

  defp decode_body(
         %{"properties" => _properties, "nextPageToken" => _next_page} = body,
         %{options: %{auto_page: true}} = request
       ) do
    # Remove the :ga_decode step during the recursive process
    request = update_in(request, [Access.key!(:response_steps)], &Keyword.delete(&1, :ga_decode))
    recursive_decode_body(body, request)
  end

  defp decode_body(%{"properties" => properties, "nextPageToken" => page_token} = _body, _options) do
    ReqGA.PropertyList.new(properties, page_token)
  end

  defp decode_body(%{"properties" => properties} = _body, _options) do
    ReqGA.PropertyList.new(properties)
  end

  # For accounts (via Admin API)
  defp decode_body(%{"accounts" => accounts} = _body, _options) do
    AccountList.new(accounts)
  end

  # For account summaries (via Admin API)
  defp decode_body(%{"accountSummaries" => accnt_summaries} = _body, _options) do
    AccountList.new(accnt_summaries)
  end

  # For custom dimensions (via Admin API)
  defp decode_body(%{"customDimensions" => custom_dimensions} = _body, _options) do
    custom_dimensions
    |> Enum.map(fn cust_dimension -> Map.drop(cust_dimension, ["name"]) end)
    |> Enum.sort(&(&1["displayName"] < &2["displayName"]))
  end

  # For custom metrics (via Admin API)
  defp decode_body(%{"customMetrics" => custom_metrics} = _body, _options) do
    custom_metrics
    |> Enum.map(fn cust_dimension -> Map.drop(cust_dimension, ["name"]) end)
    |> Enum.sort(&(&1["displayName"] < &2["displayName"]))
  end

  # For reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#runReport"} = body, _options) do
    ReportResponse.new(body)
  end

  # For batch reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#batchRunReports"} = body, _options) do
    Enum.map(body["reports"], fn report -> ReportResponse.new(report) end)
  end

  # For pivot reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#runPivotReport"} = body, _options) do
    PivotReportResponse.new(body)
  end

  # For batch run pivot reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#batchRunPivotReports"} = body, _options) do
    Enum.map(body["pivotReports"], fn report -> PivotReportResponse.new(report) end)
  end

  # For realtime reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#runRealtimeReport"} = body, _options) do
    ReportResponse.new(body)
  end

  # For account get requests (via Admin API)
  defp decode_body(body, %{method: :get, options: %{ga: :accounts}} = _options) do
    Account.new(body)
  end

  # For properties get requests (via Admin API)
  defp decode_body(body, %{method: :get, options: %{ga: :properties}} = _options) do
    Property.new(body)
  end

  # Catch all
  defp decode_body(body, _options) do
    body
  end

  ## --------------------
  ## Get token from Goth
  ## --------------------
  defp get_token(options) do
    goth = options[:goth] || raise ":goth is missing"
    Goth.fetch!(goth).token
  end

  ## -------------------
  ## Endpoint helpers
  ## -------------------

  # For compatibility check endpoint (via Data API)
  defp uri_for(%{ga: :check_compatibility, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}:checkCompatibility")
  end

  # For metadata endpoint (via Data API)
  defp uri_for(%{ga: :metadata, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}/metadata")
  end

  # For run report (via Data API)
  defp uri_for(%{ga: :run_report, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}:runReport")
  end

  # For batch run reports (via Data API)
  defp uri_for(%{ga: :batch_run_reports, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}:batchRunReports")
  end

  # For run pivot report (via Data API)
  defp uri_for(%{ga: :run_pivot_report, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}:runPivotReport")
  end

  # For batch run pivot reports (via Data API)
  defp uri_for(%{ga: :batch_run_pivot_reports, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}:batchRunPivotReports")
  end

  # For run realtime report (via Data API)
  defp uri_for(%{ga: :run_realtime_report, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}:runRealtimeReport")
  end

  # For list audience exports (via Data API)
  defp uri_for(%{ga: :audience_exports, property_id: property_id} = _options) do
    URI.parse("#{@base_data_url}/#{property_id}/audienceExports")
  end

  # For list audiences report (via Data API)
  defp uri_for(%{ga: :audience_list, property_id: property_id} = _options) do
    URI.parse("#{@base_data_alpha_url}/#{property_id}/audienceLists")
  end

  # For account actions using an account ID (via Admin API)
  defp uri_for(%{ga: :accounts, account_id: account_id} = _options) do
    URI.parse("#{@base_admin_url}/#{account_id}")
  end

  # For properties actions using an property ID (via Admin API)
  defp uri_for(%{ga: :properties, property_id: property_id} = _options) do
    URI.parse("#{@base_admin_url}/#{property_id}")
  end

  # For a generic Admin API endpoint using a property ID
  defp uri_for(%{ga: ga_method, property_id: property_id} = _options) do
    endpoint =
      Keyword.get(@ga_enpoints, ga_method) ||
        raise "invalid :ga method. Valid :ga methods are: #{inspect(Keyword.keys(@ga_enpoints))}"

    URI.parse("#{@base_admin_url}/#{property_id}/#{endpoint}")
  end

  # For a generic Admin API endpoint
  defp uri_for(options) do
    ga_method =
      options[:ga] ||
        raise ":ga is missing. Set :ga with one of the following: #{inspect(Keyword.keys(@ga_enpoints))}"

    endpoint =
      Keyword.get(@ga_enpoints, ga_method) ||
        raise "invalid :ga method. Valid :ga methods are: #{inspect(Keyword.keys(@ga_enpoints))}"

    URI.parse("#{@base_admin_url}/#{endpoint}")
  end
end
