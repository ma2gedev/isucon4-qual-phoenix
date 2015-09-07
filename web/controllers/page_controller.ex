defmodule Isucon4.PageController do
  use Isucon4.Web, :controller

  alias Isucon4.User
  alias Isucon4.LoginLog
  alias Ecto.DateTime

  @user_lock_threshold 3
  @ip_ban_threshold 10

  def index(conn, _params) do
    render conn, "index.html"
  end

  def login(conn, params) do
    case attempt_login(conn, Map.get(params, "login"), Map.get(params, "password")) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: page_path(conn, :mypage))
      {:error, reason} ->
        message = case reason do
          :locked -> "This account is locked."
          :banned -> "You're banned."
          _ -> "Wrong username or password"
        end
        conn
        |> put_flash(:notice, message)
        |> redirect(to: page_path(conn, :index))
    end
  end

  def mypage(conn, _params) do
    case current_user(conn) do
      nil ->
        conn
        |> put_session(:user_id, nil)
        |> redirect(to: page_path(conn, :index))
      user ->
        last_login = LoginLog.last_login(user.id)
                     |> Repo.all
                     |> List.last
        render conn, "mypage.html", last_login: last_login
    end
  end

  def report(conn, _params) do
    render conn, "report.json", banned_ips: banned_ips, locked_users: locked_users
  end

  defp login_log(remote_ip, succeeded, login, user_id \\ nil) do
    Repo.insert(LoginLog.changeset(%LoginLog{}, %{ip: remote_ip, created_at: DateTime.from_erl(:calendar.local_time), succeeded: succeeded, login: login, user_id: user_id}))
  end

  defp ip_to_string(ip) do
    ip |> Tuple.to_list |> Enum.join(".")
  end

  defp attempt_login(conn, login, password) do
    user = User.by_login(login)
           |> Repo.one

    user_id = if user, do: user.id, else: nil
    remote_ip = conn.remote_ip |> ip_to_string
    cond do
      ip_banned?(remote_ip) ->
        login_log(remote_ip, false, login, user_id)
        {:error, :banned}
      user_locked?(user) ->
        login_log(remote_ip, false, login, user_id)
        {:error, :locked}
      user && calculate_password_hash(password, user.salt) == user.password_hash ->
        login_log(remote_ip, true, login, user_id)
        {:ok, user}
      user ->
        login_log(remote_ip, false, login, user_id)
        {:error, :wrong_password}
      true ->
        login_log(remote_ip, false, login, user_id)
        {:error, :wrong_login}
    end
  end

  defp ip_banned?(remote_ip) do
    failure_count = Repo.one(LoginLog.failures_by_ip(remote_ip))
    @ip_ban_threshold <= failure_count
  end

  defp user_locked?(nil), do: false
  defp user_locked?(user) do
    failure_count = Repo.one(LoginLog.failures_by_user(user))
    @user_lock_threshold <= failure_count
  end

  defp calculate_password_hash(password, salt) do
    :crypto.hash(:sha256, "#{password}:#{salt}") |> Base.encode16 |> String.downcase
  end

  defp current_user(conn) do
    user_id = get_session(conn, :user_id)
    if user_id == nil do
      nil
    else
      Repo.get(User, user_id)
    end
  end

  defp banned_ips do
    ips = []
    threshold = @ip_ban_threshold

    {:ok, %{rows: not_succeeded}} = Ecto.Adapters.SQL.query(Repo, "SELECT ip FROM (SELECT ip, MAX(succeeded) as max_succeeded, COUNT(1) as cnt FROM login_log GROUP BY ip) AS t0 WHERE t0.max_succeeded = 0 AND t0.cnt >= ?", [threshold])
    ips = ips ++ Enum.map(not_succeeded, fn ([ip]) -> ip end)

    {:ok, %{rows: last_succeeds}} = Ecto.Adapters.SQL.query(Repo, "SELECT ip, MAX(id) AS last_login_id FROM login_log WHERE succeeded = 1 GROUP by ip", [])

    ip_list = Enum.reduce(last_succeeds, [], fn ([ip, last_login_id], acc) ->
      {:ok, %{rows: [[cnt]]}} = Ecto.Adapters.SQL.query(Repo, "SELECT COUNT(1) AS cnt FROM login_log WHERE ip = ? AND ? < id", [ip, last_login_id])
      if threshold <= cnt do
        acc ++ [ip]
      else
        acc
      end
    end)

    ips ++ ip_list
  end

  defp locked_users do
    user_ids = []
    threshold = @user_lock_threshold

    {:ok, %{rows: not_succeeded}} = Ecto.Adapters.SQL.query(Repo, "SELECT user_id, login FROM (SELECT user_id, login, MAX(succeeded) as max_succeeded, COUNT(1) as cnt FROM login_log GROUP BY user_id) AS t0 WHERE t0.user_id IS NOT NULL AND t0.max_succeeded = 0 AND t0.cnt >= ?", [threshold])
    user_ids = user_ids ++ Enum.map(not_succeeded, fn ([_, l]) -> l end)

    {:ok, %{rows: last_succeeds}} = Ecto.Adapters.SQL.query(Repo, "SELECT user_id, login, MAX(id) AS last_login_id FROM login_log WHERE user_id IS NOT NULL AND succeeded = 1 GROUP BY user_id", [])

    ids = Enum.reduce(last_succeeds, [], fn ([user_id, login, last_login_id], acc) ->
      {:ok, %{rows: [[cnt]]}} = Ecto.Adapters.SQL.query(Repo, "SELECT COUNT(1) AS cnt FROM login_log WHERE user_id = ? AND ? < id", [user_id, last_login_id])
      if threshold <= cnt do
        acc ++ [login]
      else
        acc
      end
    end)

    user_ids ++ ids
  end
end
