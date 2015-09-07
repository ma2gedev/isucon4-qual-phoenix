defmodule Isucon4.PageView do
  use Isucon4.Web, :view

  def render("report.json", data) do
    %{banned_ips: data.banned_ips, locked_users: data.locked_users}
  end
end
