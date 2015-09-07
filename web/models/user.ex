defmodule Isucon4.User do
  use Isucon4.Web, :model

  schema "users" do
    field :login, :string
    field :password_hash, :string
    field :salt, :string
  end

  @required_fields ~w(login password_hash salt)
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

  def by_login(login) do
    from u in Isucon4.User,
    where: u.login == ^login
  end
end
