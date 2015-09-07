defmodule Isucon4.LoginLog do
  use Isucon4.Web, :model

  schema "login_log" do
    field :created_at, Ecto.DateTime
    field :user_id, :integer
    field :login, :string
    field :ip, :string
    field :succeeded, :boolean
  end

  @required_fields ~w(created_at user_id login ip succeeded)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def last_login(user_id) do
    from l in Isucon4.LoginLog,
    where: l.succeeded == true,
    where: l.user_id == ^user_id,
    order_by: [desc: l.id],
    limit: 2
  end

  def failures_by_ip(remote_ip) do
    from l in Isucon4.LoginLog,
    where: l.ip == ^remote_ip,
    where: fragment("id > IFNULL((select id from login_log where ip = ? AND succeeded = 1 ORDER BY id DESC LIMIT 1), 0)", ^remote_ip),
    select: count(1)
  end

  def failures_by_user(user) do
    from l in Isucon4.LoginLog,
    where: l.user_id == ^user.id,
    where: fragment("id > IFNULL((select id from login_log where user_id = ? AND succeeded = 1 ORDER BY id DESC LIMIT 1), 0)", ^user.id),
    select: count(1)
  end
end
