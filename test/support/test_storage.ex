defmodule Shaere.TestStorage do
  @moduledoc false
  use GenServer

  @behaviour Shaere.StorageAdapterType

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(_opts) do
    __MODULE__ = :ets.new(__MODULE__, [:named_table])
    {:ok, []}
  end

  # TODO
  @impl Shaere.StorageAdapterType
  def privkey(telegram_id) do
    GenServer.call(__MODULE__, {:privkey, telegram_id})
  end

  @doc false
  def clean do
    GenServer.call(__MODULE__, :clean)
  end

  @doc false
  def lookup(telegram_id) do
    case :ets.lookup(__MODULE__, telegram_id) do
      [{^telegram_id, privkey}] -> privkey
      [] -> nil
    end
  end

  @doc false
  def handle_call({:privkey, telegram_id}, _from, state) do
    privkey =
      if privkey = lookup(telegram_id) do
        privkey
      else
        privkey = Shaere.Ae.keypair().secret
        true = :ets.insert(__MODULE__, {telegram_id, privkey})
        privkey
      end

    {:reply, privkey, state}
  end

  def handle_call(:clean, _from, state) do
    {:reply, :ets.delete_all_objects(__MODULE__), state}
  end
end
