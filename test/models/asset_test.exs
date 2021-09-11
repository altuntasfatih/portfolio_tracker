defmodule AssetTest do
  use ExUnit.Case

  @name "Test"
  @asset_type :bist
  @total 100
  @cost_price 10.0

  test "it_should_create_asset" do
    assert Asset.new(@name, @asset_type, @total, @cost_price) == %Asset{
             name: @name,
             type: @asset_type,
             total: @total,
             cost_price: @cost_price,
             cost: 1000.0,
             price: 10.0,
             value: 1000.0,
             rate: 0.0
           }
  end

  test "it_should_calculate_asset_value, " do
    new_price = 13.41

    assert Asset.new(@name, @asset_type, @total, @cost_price) |> Asset.update(new_price) ==
             %Asset{
               name: @name,
               type: @asset_type,
               total: @total,
               cost_price: @cost_price,
               cost: 1000.0,
               price: new_price,
               value: 1341.0,
               rate: 34.11
             }
  end

  test "it_should_calculate_asset_value_when_rate_is_negative " do
    new_price = 8.57

    assert Asset.new(@name, @asset_type, @total, @cost_price) |> Asset.update(new_price) ==
             %Asset{
               name: @name,
               type: @asset_type,
               total: @total,
               cost_price: @cost_price,
               cost: 1000.0,
               price: new_price,
               value: 857.0,
               rate: -14.29
             }
  end
end
