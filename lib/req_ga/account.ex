defmodule ReqGA.Account do
    defstruct [
      :account, :display_name, :resource_name,
      create_time: nil, update_time: nil, region_code: nil,
      property_summaries: []
      ]
  
    def new(account) do
      %__MODULE__{
        account: account["account"] || "Unknown",
        display_name: account["displayName"] || "Unknown",
        resource_name: account["name"] || nil,
        create_time: account["createTime"] || nil,
        update_time: account["updateTime"] || nil,
        region_code: account["regionCode"] || nil,
        property_summaries: populate_property_summaries(account["propertySummaries"])
      }
    end
  
    defp populate_property_summaries(nil), do: []
    defp populate_property_summaries(properties) when is_list(properties) do
      Enum.map(properties, &ReqGA.Property.new/1)  
    end
end

if Code.ensure_loaded?(Table.Reader) do
  defimpl Table.Reader, for: ReqGA.Account do
    def init(account) do
      cols = [:account, :account_display_name, :property, :property_display_name, :property_type]
      rows =
        Enum.map(account.property_summaries, fn prop ->
          [account.account, account.display_name, prop.property, prop.display_name, prop.property_type]
        end)
  
      {:rows, %{columns: cols, count: length(rows)}, rows}
    end
  end
end