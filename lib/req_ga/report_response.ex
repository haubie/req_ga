defmodule ReqGA.ReportResponse do
  @doc """
  A struct representing a report response

    Has the following keys:
    - `dimensions:` a list of the dimension in the report
    - `metrics:` a list of the metric names in the report as well as their type, in tuple format e.g. `{"activeUsers", "TYPE_INTEGER"}`
    - `columns:` the column names for each row (dimension names first, followed by metric names)
    - `rows:` a list containing the row's data
    - `totals:` used for reports with total
    - `maximums:` used for reports with maximums
    - `minimums:` used for reports with minimums
    - `count:` the number of results (rows)
    - `property_quota:` property quota data (if returned)
    - `metadata:` associated with the report and property, such as currency code, time zone information and if the data is subject to thresholding.

    Implements the `Table.Reader` reader protocol.
  """
  defstruct [:dimensions, :metrics, :columns, :rows, :totals, :maximums, :minimums, :count, :property_quota, metadata: %{}]
    
  def new(body) do

    dimensions = parse_dimensions(body["dimensionHeaders"])
    metrics = parse_metrics(body["metricHeaders"])
    columns = dimensions ++ Enum.map(metrics, fn {metric, _type} -> metric end)

    %__MODULE__{
      dimensions: dimensions,
      metrics: metrics,
      columns: columns,
      rows: if(body["rows"], do: parse_rows(body["rows"], metrics), else: nil),
      totals: body["totals"],
      maximums: body["maximums"],
      minimums: body["minimums"],
      count: body["rowCount"],
      metadata: body["metadata"],
      property_quota: body["propertyQuota"]
    }

  end

  defp parse_dimensions(dimensions) do
    Enum.map(dimensions, fn %{"name" => dimension} -> dimension end)
  end

  defp parse_metrics(metrics) do
    Enum.map(metrics, fn %{"name" => metric, "type" => type} -> {metric, type} end)
  end

  defp parse_rows(rows, metrics) do
    rows
    |> Enum.map(fn %{"dimensionValues" => dimension_values, "metricValues" => metric_values} ->
      parse_values(dimension_values) ++ parse_values(metric_values, metrics)
    end)
    
  end

  defp parse_values(values) do
    Enum.map(values, fn %{"value" => value} -> value end)
  end

  defp parse_values(values, types) do
    Enum.zip(values, types)
    |> Enum.map(fn {%{"value" => value}, {_name, type}} -> maybe_convert(value, type) end)
  end

  @integer_types ["TYPE_INTEGER", "TYPE_SECONDS"]
  @float_types ["TYPE_FLOAT", "TYPE_FLOAT"]
  @special_float_types ["TYPE_MILLISECONDS", "TYPE_MINUTES", "TYPE_HOURS", "TYPE_STANDARD", "TYPE_CURRENCY", "TYPE_FEET", "TYPE_MILES", "TYPE_METERS", "TYPE_KILOMETERS"]
  defp maybe_convert(value, types) when types in @integer_types, do: String.to_integer(value)
  defp maybe_convert(value, types) when types in @float_types, do: String.to_float(value)
  defp maybe_convert(value, types) when types in @special_float_types, do: value
  defp maybe_convert(value, _type), do: value    

end

if Code.ensure_loaded?(Table.Reader) do
  defimpl Table.Reader, for: ReqGA.ReportResponse do
    def init(report_response) do
      {:rows, %{columns: report_response.columns, count: report_response.count}, report_response.rows}
    end
  end
end
