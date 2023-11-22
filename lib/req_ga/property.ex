defmodule ReqGA.Property do
    defstruct [
      :display_name,
      :parent,
      :property,
      :property_type,
      :resource_name,
      :create_time,
      :update_time,
      :industry_category,
      :time_zone,
      :currency_code,
      :service_level,
      :account
    ]
  
    def new(property) do
      %__MODULE__{
        display_name: property["displayName"],
        parent: property["parent"],
        property: property["property"] || property["name"],
        property_type: property["propertyType"],
        resource_name: property["name"],
        create_time: property["createTime"],
        update_time: property["updateTime"],
        industry_category: property["industryCategory"],
        time_zone: property["timeZone"],
        service_level: property["serviceLevel"],
        account: property["account"],
      }
    end
  end
  