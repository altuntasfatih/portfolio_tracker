defmodule PortfolioTracker.Server do
  @moduledoc """
  Documentation for `PortfolioTracker`.
  """
  alias PortfolioTracker.ExchangeApi
  use GenServer
  require Logger

  @backup_path "./backup/"

  def start_link(%Portfolio{} = state) do
    GenServer.start_link(__MODULE__, state, name: {:global, {state.id, __MODULE__}})
  end

  def start_link(id) do
    load_create_state(id)
    |> start_link()
  end

  defp load_create_state(id) do
    case File.read(@backup_path <> "#{id}") do
      {:ok, binary} -> :erlang.binary_to_term(binary)
      _ -> Portfolio.new(id)
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:destroy, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call(:live, _from, state) do
    new_state = Portfolio.update(state, update_stocks_with_live(state.stocks))
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_cast({:add_stock, %Stock{} = stock}, state) do
    {:noreply, Portfolio.add_stock(state, stock)}
  end

  @impl true
  def handle_cast({:delete_stock, stock_id}, state) do
    {:noreply, Portfolio.delete_stock(state, stock_id)}
  end

  @impl true
  def handle_cast(:update, state), do: handle_info(:update, state)

  @impl true
  def handle_info(:update, %Portfolio{stocks: []} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:update, %Portfolio{stocks: stocks} = state) do
    {:noreply, Portfolio.update(state, update_stocks_with_live(stocks))}
  end

  @impl true
  def handle_info(:take_backup, state) do
    binary = :erlang.term_to_binary(state)

    case File.write(@backup_path <> "#{state.id}", binary) do
      :ok -> Logger.info("State was succefully back up")
      {:error, err} -> Logger.error("Back up failed err -> #{err}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:timeout, _) do
    {:stop, :normal, []}
  end

  def update_stocks_with_live(stocks, current_prices) when is_list(stocks) do
    Enum.map(stocks, fn s ->
      Enum.find(current_prices, fn x -> s.id == x.name end)
      |> calculate_stock(s)
    end)
  end

  defp update_stocks_with_live(%{} = stocks) do
    {:ok, current_prices} = ExchangeApi.get_live_prices()

    Map.values(stocks)
    |> update_stocks_with_live(current_prices)
    |> Enum.reduce(%{}, fn s, acc -> Map.put(acc, s.id, s) end)
  end

  defp calculate_stock(nil, %Stock{} = stock), do: stock
  defp calculate_stock(c, %Stock{} = stock), do: Stock.calculate(stock, c.price)

  defp take_backup(pid), do: Process.send_after(pid, :take_backup, 1000)

  def get(id), do: via_tuple(id, &GenServer.call(&1, :get))

  def add_stock(%Stock{} = stock, id), do: via_tuple(id, &GenServer.cast(&1, {:add_stock, stock}))

  def set_alert(stock_id, target_price, id),
    do: via_tuple(id, &GenServer.cast(&1, {:set_alert, stock_id, target_price}))

  def update(id), do: via_tuple(id, &GenServer.cast(&1, :update))

  def live(id), do: via_tuple(id, &GenServer.call(&1, :live))

  def delete_stock(id, stock_id),
    do: via_tuple(id, &GenServer.cast(&1, {:delete_stock, stock_id}))

  def destroy(id), do: via_tuple(id, &GenServer.call(&1, :destroy))

  def via_tuple(id, callback) do
    case :global.whereis_name({id, __MODULE__}) do
      pid when is_pid(pid) ->
        resp = callback.(pid)
        take_backup(pid)
        resp

      _ ->
        {:error, :listener_not_found}
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
