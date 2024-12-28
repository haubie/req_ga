defmodule ReqGA.PropertyList do
    @moduledoc """
    A struct containing a list of `%ReqGA.Property{}`. This represents a Google Analytics property.

    Has three keys:
    - `properties:` a list of populated `%ReqGA.Property{}` structus
    - `count:` the number of properties in the properties list
    - `page_token:` the token of the next page for multi-page responses.

    Implements the `Table.Reader` reader protocol.
    """
    defstruct [properties: [], count: 0, page_token: nil]
  
    def new(properties_list, page_token \\ nil) do
        properties = Enum.map(properties_list, &ReqGA.Property.new/1)
  
        %__MODULE__{
            properties: properties,
            count: length(properties),
            page_token: page_token
        }
    end
  
end

if Code.ensure_loaded?(Table.Reader) do
    defimpl Table.Reader, for: ReqGA.PropertyList do
        def init(properties_list) do
            cols = [
                :property,
                :property_display_name,
                :property_type,
                :property_create_time,
                :property_update_time,

                :time_zone,
                :currency_code,
                :industry_category,
     
                :parent,
                :account,
                :service_level,
            ]
            rows = Enum.map(properties_list.properties, fn p ->
                [
                    p.property,
                    p.display_name,
                    p.property_type,
                    p.create_time,
                    p.update_time,
                
                    p.time_zone,
                    p.currency_code,
                    p.industry_category,
                
                    p.parent,
                    p.account,
                    p.service_level
                ]
             end)
            {:rows, %{columns: cols, count: length(rows)}, rows}
        end

    end
end

