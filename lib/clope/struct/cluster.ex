defmodule Clope.Struct.Cluster do
  defstruct uuid: nil, transactions: [], transaction_count: 0,
    item_count: 0,  occ: %{}, width: 0

  alias Clope.Struct.Transaction
  alias Clope.Struct.Cluster
  alias Clope.Struct.Item
  @moduledoc false

  def new do
    %Cluster{uuid: UUID.uuid4}
  end

  def add_transaction(
      %Cluster{transactions: transactions} = cluster,
      %Transaction{} = transaction) do
    if transactions |> Enum.member?(transaction) do
      cluster
    else
      _add_transaction(cluster, transaction)
    end
  end

  def remove_transaction(
      %Cluster{transactions: transactions} = cluster,
      %Transaction{} = transaction) do
    if transactions |> Enum.member?(transaction) do
      _remove_transaction(cluster, transaction)
    else
      cluster
    end
  end

  def equal?(
      %Cluster{uuid: uuid1},
      %Cluster{uuid: uuid2}) do
    uuid1 == uuid2
  end

  def member?(
      %Cluster{transactions: transactions},
      %Transaction{} = transaction) do
    transactions |> Enum.member?(transaction)
  end

  defp _add_transaction(
      %Cluster{
        transactions: transactions,
        item_count: item_count,
        transaction_count: transaction_count,
        occ: occ,
        uuid: uuid
      },
      %Transaction{items: items} = transaction) do
    new_transactions = transactions ++ [transaction]
    new_transaction_count = transaction_count + 1
    {
      new_width,
      new_item_count,
      new_occ
    } = recalculate_stats(:add, items, item_count, occ)

    %Cluster{
      transactions: new_transactions,
      item_count: new_item_count,
      transaction_count: new_transaction_count,
      width: new_width,
      item_count: new_item_count,
      occ: new_occ,
      uuid: uuid
    }
  end

  defp _remove_transaction(
      %Cluster{
        transactions: transactions,
        item_count: item_count,
        transaction_count: transaction_count,
        occ: occ,
        uuid: uuid
      },
      %Transaction{items: items} = transaction) do
    new_transactions = transactions -- [transaction]
    new_transaction_count = transaction_count - 1
    {
      new_width,
      new_item_count,
      new_occ
    } = recalculate_stats(:remove, items, item_count, occ)

    %Cluster{
      transactions: new_transactions,
      item_count: new_item_count,
      transaction_count: new_transaction_count,
      width: new_width,
      item_count: new_item_count,
      occ: new_occ,
      uuid: uuid
    }
  end

  defp recalculate_stats(:add, items, previous_item_count, previous_occ) do
    acc = {previous_item_count, previous_occ}

    {new_item_count, new_occ} =
      items
      |> Enum.reduce(acc, fn(%Item{value: value}, {item_count, occ}) ->
        occ = occ |> Map.update(value, 1, &(&1 + 1))

        {item_count + 1, occ}
      end)
    new_width = new_occ |> Enum.count

    {new_width, new_item_count, new_occ}
  end

  defp recalculate_stats(:remove, items, previous_item_count, previous_occ) do
    acc = {previous_item_count, previous_occ}

    {new_item_count, new_occ} =
      items
      |> Enum.reduce(acc, fn(%Item{value: value}, {item_count, occ}) ->
        occ = occ |> Map.update(value, 1, &(&1 - 1))

        {item_count - 1, occ}
      end)

    new_occ =
      new_occ |> Enum.drop_while(fn({_key, val}) ->
        val == 0
      end)
      |> Map.new(fn(pair) -> pair  end)
    new_width = new_occ |> Enum.count

    {new_width, new_item_count, new_occ}
  end
end
