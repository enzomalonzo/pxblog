defmodule Pxblog.PostTest do
  use Pxblog.ModelCase

  alias Pxblog.Post

  @valid_attrs %{body: "some content", title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Post.changeset(%Post{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Post.changeset(%Post{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "renders form for new resources", %{conn: conn} do
      conn = get conn, post_path(conn, :new)
        assert html_response(conn, 200) =~ "New post"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = get conn, post_path(conn, :new), post: @valid_attrs
    assert redirected_to(conn) == post_path(conn, :index)
    assert Repo.get_by(Post, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = get conn, post_path(conn, :new), post: @invalid_attrs
    assert html_response(conn, 200) =~ "New post"
  end

  test "show chosen resource", %{conn: conn} do
    post = Repo.insert! %Post{}
    conn = get conn, post_path(conn, :show, post)
    assert html_response(conn, 200) =~ "Show post"
  end

  test "renders page not found when id is non existent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, post_path(conn, :show, -1)
    end
  end
end
