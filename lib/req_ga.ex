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
  | :account_summaries        | Admin API | "/accountSummaries"       | get                       |
  | :custom_dimensions        | Admin API | "/customDimensions"       | get, post                 |
  | :custom_metrics           | Admin API | "/customMetrics"          | get, post                 |


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

  @allowed_options ~w(goth ga property_id show_deleted)a

  @base_admin_url "https://analyticsadmin.googleapis.com/v1beta"
  @base_data_url "https://analyticsdata.googleapis.com/v1beta"
  
  @ga_enpoints [
    run_report: "runReport",
    batch_run_reports: "batchRunReports",
    run_pivot_report:  "runPivotReport",
    batch_run_pivot_reports: "batchRunPivotReports",
    run_realtime_report: "runRealtimeReport",
    metadata: "metadata",
    check_compatibility: "checkCompatibility",
    account_summaries: "accountSummaries",
    custom_dimensions: "customDimensions",
    custom_metrics: "customMetrics",
    accounts: "accounts"
  ]

  alias Req.Request
  alias ReqGA.{AccountList, ReportResponse, PivotReportResponse}

  @doc """
  Attaches ReqGA to Req's request and response steps.

  ## Example
  Assuming a Goth process was started with the name `GA`:
  ```
  req = Req.new() |> ReqGA.attach(goth: GA)
  ```
  """
  def attach(%Request{}=request, options \\ []) do
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
    {request, update_in(response.body, &decode_body(&1, request.options))}
  end
  defp decode(any), do: any


  

  # For accounts (via Admin API)
  defp decode_body(%{"accounts" => accounts}=_body, _options) do
    AccountList.new(accounts)
  end

  # For account summaries (via Admin API)
  defp decode_body(%{"accountSummaries" => accnt_summaries}=_body, _options) do
      AccountList.new(accnt_summaries)
  end

  # For custom dimensions (via Admin API)
  defp decode_body(%{"customDimensions" => custom_dimensions}=_body, _options) do
    custom_dimensions
    |> Enum.map(fn cust_dimension -> Map.drop(cust_dimension, ["name"]) end)
    |> Enum.sort(&(&1["displayName"] < &2["displayName"]))   
  end

  # For custom metrics (via Admin API)
  defp decode_body(%{"customMetrics" => custom_metrics}=_body, _options) do
    custom_metrics
    |> Enum.map(fn cust_dimension -> Map.drop(cust_dimension, ["name"]) end)
    |> Enum.sort(&(&1["displayName"] < &2["displayName"]))   
  end

  # For reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#runReport"}=body, _options) do
    ReportResponse.new(body)
  end

  # For batch reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#batchRunReports"}=body, _options) do
    Enum.map(body["reports"], fn report -> ReportResponse.new(report) end)
  end

   # For pivot reports (via Data API)
   defp decode_body(%{"kind" => "analyticsData#runPivotReport"}=body, _options) do
    PivotReportResponse.new(body)
  end

  # For batch run pivot reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#batchRunPivotReports"}=body, _options) do
    Enum.map(body["pivotReports"], fn report -> PivotReportResponse.new(report) end)
  end

  # For realtime reports (via Data API)
  defp decode_body(%{"kind" => "analyticsData#runRealtimeReport"}=body, _options) do
    ReportResponse.new(body)
  end


  # Catch all
  defp decode_body(body, _options), do: body 

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
  defp uri_for(%{ga: :check_compatibility, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:checkCompatibility")
  end

  # For metadata endpoint (via Data API)
  defp uri_for(%{ga: :metadata, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}/metadata")
  end

  # For run report (via Data API)
  defp uri_for(%{ga: :run_report, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:runReport")
  end

  # For batch run reports (via Data API)
  defp uri_for(%{ga: :batch_run_reports, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:batchRunReports")
  end

  # For run pivot report (via Data API)
  defp uri_for(%{ga: :run_pivot_report, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:runPivotReport")
  end

  # For batch run pivot reports (via Data API)
  defp uri_for(%{ga: :batch_run_pivot_reports, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:batchRunPivotReports")
  end

  # For run realtime report (via Data API)
  defp uri_for(%{ga: :run_realtime_report, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:runRealtimeReport")
  end

  # For a generic Admin API endpoint using a property ID 
  defp uri_for(%{ga: ga_method, property_id: property_id}=_options) do
    endpoint = Keyword.get(@ga_enpoints, ga_method) || raise "invalid :ga method. Valid :ga methods are: #{inspect(Keyword.keys(@ga_enpoints))}"

    URI.parse("#{@base_admin_url}/#{property_id}/#{endpoint}")
  end

  # For a generic Admin API endpoint
  defp uri_for(options) do
    ga_method = options[:ga] || raise ":ga is missing. Set :ga with one of the following: #{inspect(Keyword.keys(@ga_enpoints))}"
    endpoint = Keyword.get(@ga_enpoints, ga_method) || raise "invalid :ga method. Valid :ga methods are: #{inspect(Keyword.keys(@ga_enpoints))}"
    
    URI.parse("#{@base_admin_url}/#{endpoint}")
  end

end