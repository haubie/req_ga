defmodule ReqGA do
  @moduledoc """
  A Req plugin for interacting with Google Analytics 4 APIs.

  ## Currently implemented methods
  | :ga API method     | API       | Endpoint            | Req HTTP method supported |
  | ------------------ | --------- | ------------------- | ------------------------- |
  | :account_summaries | Admin API | "/accountSummaries" | get |
  | :custom_dimensions | Admin API | "/customDimensions" | get |
  | :custom_metrics    | Admin API | "/customMetrics"    | get |
  | :run_report        | Data API  | ":runReport"        | post |
  | :metadata          | Data API  | "/metadata"         | get |

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
  - ReqGA.AccountList
  - ReqGA.Account

  This makes it easier to view in LiveBook as a table by piping it to `Kino.DataTable.new` or for creating a DataFrame with `Explorer.DataFrame.new`.
  """

  @allowed_options ~w(goth ga property_id)a

  @base_admin_url "https://analyticsadmin.googleapis.com/v1beta"
  @base_data_url "https://analyticsdata.googleapis.com/v1beta"
  
  @ga_enpoints [
    account_summaries: "accountSummaries",
    custom_dimensions: "customDimensions",
    custom_metrics: "customMetrics",
    run_report: "runReport",
    metadata: "metadata"
  ]

  alias Req.Request
  alias ReqGA.{AccountList,ReportResponse}

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

  # For metadata endpoint (via Data API)
  defp uri_for(%{ga: :metadata, property_id: property_id}=_options) do
    property_id = property_id || raise ":property_id is missing."
    URI.parse("#{@base_data_url}/#{property_id}/metadata")
  end

  # For run report (via Data API)
  defp uri_for(%{ga: :run_report, property_id: property_id}=_options) do
    URI.parse("#{@base_data_url}/#{property_id}:runReport")
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