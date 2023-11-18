defmodule ReqGA.Account do
    @moduledoc """
    A struct containing representing a Google Analytics account.

    Has the following keys:
    - account: name of the account in the format "accounts/{account_id}", e.g. "accounts/1000"
    - display_name: human readable name (string) of the account
    - resource_name: the resource name. For example if populated from an account summmary, it will be in the format "accountSummaries/{account_id}", e.g.: "accountSummaries/1000"
    - create_time: time when this account was originally created
    - update_time: time when account payload fields were last updated
    - region_code: country of business, a unicode CLDR region code
    - deleted: whether this Account is soft-deleted (true) or not (false). Deleted accounts are excluded from List results unless specifically requested.
    - property_summaries: a list of property summaries if populated by call to `:account_summaries`, otherwise an empty lust.

    Implements the `Table.Reader` reader protocol.
    """
    defstruct [
      :account, :display_name, :resource_name,
      create_time: nil, update_time: nil, region_code: nil, deleted: false,
      property_summaries: []
      ]
  
    def new(account) do
      %__MODULE__{
        account: account["account"] || account["name"] || "Unknown",
        display_name: account["displayName"] || "Unknown",
        resource_name: account["name"] || nil,
        create_time: account["createTime"] || nil,
        update_time: account["updateTime"] || nil,
        region_code: account["regionCode"] || nil,
        deleted: account["deleted"] || false,
        property_summaries: if(account["propertySummaries"], do: populate_property_summaries(account["propertySummaries"]), else: [])
      }
    end
  
    defp populate_property_summaries(nil), do: []
    defp populate_property_summaries(properties) when is_list(properties) do
      Enum.map(properties, &ReqGA.Property.new/1)  
    end
end

if Code.ensure_loaded?(Table.Reader) do
  defimpl Table.Reader, for: ReqGA.Account do
    def init(account) when account.property_summaries != [] do
      cols = [:account, :account_display_name, :property, :property_display_name, :property_type]
      rows =
        Enum.map(account.property_summaries, fn prop ->
          [account.account, account.display_name, prop.property, prop.display_name, prop.property_type]
        end)
  
      {:rows, %{columns: cols, count: length(rows)}, rows}
    end

    def init(account) do
      cols = [:account, :account_display_name]
      rows = [account.account, account.display_name]
  
      {:rows, %{columns: cols, count: 1}, [rows]}
    end
  end
end