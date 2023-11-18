defmodule ReqGA.AccountList do
    @moduledoc """
    A struct containing a list of `%ReqGA.Account{}`. This represents a Google Analytics account.

    Has two keys:
    - `accounts:` a list of populated `%ReqGA.Account{}` structus
    - `count:` the number of accounts in the account list

    Implements the `Table.Reader` reader protocol.
    """
    defstruct [accounts: [], count: 0]
  
    def new(account_list) do
      accounts = Enum.map(account_list, &ReqGA.Account.new/1)
  
      %__MODULE__{
        accounts: accounts,
        count: length(accounts)
      }
    end
  
end

if Code.ensure_loaded?(Table.Reader) do
    defimpl Table.Reader, for: ReqGA.AccountList do
        def init(account_list) do
            cols = [:account, :account_display_name, :property, :property_display_name, :property_type]
            rows = Enum.flat_map(account_list.accounts, &row_for_account/1)
            {:rows, %{columns: cols, count: length(rows)}, rows}
        end

        defp row_for_account(account) do
            Enum.map(account.property_summaries, fn prop ->
                [account.account, account.display_name, prop.property, prop.display_name, prop.property_type]
            end)   
        end
    end
end
