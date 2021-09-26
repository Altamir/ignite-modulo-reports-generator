defmodule ReportsGenerator do
  alias ReportsGenerator.Parser

  @avaliable__foods [
    "açaí",
    "churrasco",
    "esfirra",
    "hambúrguer",
    "pastel",
    "pizza",
    "prato_feito",
    "sushi"
  ]

  @options [
    "foods",
    "users"
  ]

  def build(filename) do
    filename
    |> Parser.parser_file()
    |> Enum.reduce(report_acc(), fn [id, product_name, price], report ->
      sum_values([id, product_name, price], report)
    end)
  end

  def build_for_many(filenames) when not is_list(filenames) do
    {:error, "Please  provider a list of paths."}
  end

  def build_for_many(filenames) when is_list(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(result, report) end)

    {:ok, result}
  end

  def fetch_higth_cost(report, option) when option in @options do
    {:ok, Enum.max_by(report[option], fn {_key, value} -> value end)}
  end

  def fetch_higth_cost(_report, _option), do: {:error, "Option invalid"}

  defp sum_reports(
         %{"users" => users1, "foods" => foods1},
         %{"users" => users2, "foods" => foods2}
       ) do
    users = merge_maps(users1, users2)
    foods = merge_maps(foods1, foods2)

    build_reports(users, foods)
  end

  defp merge_maps(m1, m2) do
    Map.merge(m1, m2, fn _k, v1, v2 -> v1 + v2 end)
  end

  defp sum_values(
         [id, product_name, price],
         %{
           "users" => users,
           "foods" => foods
         }
       ) do
    users = Map.put(users, id, users[id] + price)
    foods = Map.put(foods, product_name, foods[product_name] + 1)

    build_reports(users, foods)
  end

  defp report_acc do
    users = Enum.into(1..30, %{}, &{Integer.to_string(&1), 0})
    foods = Enum.into(@avaliable__foods, %{}, &{&1, 0})

    build_reports(users, foods)
  end

  defp build_reports(users, foods) do
    %{"users" => users, "foods" => foods}
  end
end
