defmodule Pxblog.User do
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]
  use Pxblog.Web, :model

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_digest, :string

    has_many :posts, Pxblog.Post
    belongs_to :role, Pxblog.Role

    timestamps()

    #Virtual Fields
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
  end

  #%User{} |> User.changeset(%{username: "enzo", password: "password", confirm_password: "password", role_id: 0}) |> Repo.insert!

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :email, :password, :password_confirmation, :role_id])
    |> validate_required([:username, :email, :password, :password_confirmation, :role_id])
    |> hash_password
  end

  defp hash_password(changeset) do
   if password = get_change(changeset, :password) do
      changeset
      |> put_change(:password_digest, hashpwsalt(password))
    else
      changeset
    end
  end
end
