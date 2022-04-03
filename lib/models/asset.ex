defmodule Asset do
  defstruct id: "",
            name: "",
            total: 0.0,
            type: nil,
            cost_price: 0.0,
            cost: 0.0,
            price: 0.0,
            value: 0.0,
            rate: 0.0

  @type type :: :crypto
  @type t :: %Asset{
          id: String.t(),
          name: String.t(),
          type: type(),
          total: float(),
          cost_price: float(),
          cost: float(),
          price: float(),
          value: float(),
          rate: float()
        }

  @spec new(String.t(), type(), float(), float()) :: Asset.t()
  def new(name, type, total, price) when is_atom(type) do
    new(name, name, type, total, price)
  end

  def new(id, name, type, total, price) when is_atom(type) do
    value = (total * price) |> Util.round_ceil()

    %Asset{
      id: id,
      name: name,
      total: total,
      type: type,
      cost_price: price,
      cost: value,
      price: price,
      value: value,
      rate: 0.0
    }
  end

  @spec update(Asset.t(), float()) :: Asset.t()
  def update(%Asset{} = a, new_price) do
    value = (a.total * new_price) |> Util.round_ceil()

    %Asset{
      a
      | price: new_price,
        value: value,
        rate: ((value - a.cost) / a.cost * 100) |> Util.round_ceil()
    }
  end

  def get_asset_types(), do: [:crypto]

  @spec parse_type(String.t()) :: {:ok, type()} | {:error, any()}
  def parse_type("crypto"), do: {:ok, :crypto}
  def parse_type(_), do: {:error, "invlaid asset type"}
end
