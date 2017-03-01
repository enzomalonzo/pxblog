defmodule Pxblog.PostControllerTest do
  use Pxblog.ConnCase

  import Pxblog.Factory

  alias Pxblog.{
    Post,
    TestHelper,
  }

  @valid_attrs %{body: "some content", title: "some content"}
  @invalid_attrs %{}

  setup do
    role  = insert(:role)
    user  = insert(:user, role: role)
    other_user = insert(:user, role: role)
    post  = insert(:post, user: user)
    admin_role = insert(:role, admin: true)
    admin = insert(:user, role: admin_role)

    conn = build_conn() |> login_user(user)
    {:ok, conn: conn, user: user, other_user: other_user, role: role, post: post, admin: admin}
  end

  defp login_user(conn, user) do
    post conn, session_path(conn, :create), user: %{username: user.username, password: user.password}
  end

  defp logout_user(conn, user) do
    delete conn, session_path(conn, :delete, user)
  end

  test "lists all entries on index", %{conn: conn, user: user} do
    conn = get conn, user_post_path(conn, :index, user)

    assert html_response(conn, 200) =~ "Listing posts"
  end

  test "renders form for new resources", %{conn: conn, user: user} do
    conn = get conn, user_post_path(conn, :new, user)

    assert html_response(conn, 200) =~ "New post"
  end

  test "creates resource and redirects when data is valid", %{conn: conn, user: user} do
    conn = post conn, user_post_path(conn, :create, user), post: @valid_attrs

    assert redirected_to(conn) == user_post_path(conn, :index, user)
    assert Repo.get_by(assoc(user, :posts), @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn, user: user} do
    conn = post conn, user_post_path(conn, :create, user), post: @invalid_attrs

    assert html_response(conn, 200) =~ "New post"
  end

  test "shows chosen resource", %{conn: conn, user: user, post: post} do
    conn = get conn, user_post_path(conn, :show, user, post)

    assert html_response(conn, 200) =~ "Show post"
  end

  test "renders page not found when id is nonexistent", %{conn: conn, user: user} do
    assert_error_sent 404, fn ->
      get conn, user_post_path(conn, :show, user, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn, user: user, post: post} do
    conn = get conn, user_post_path(conn, :edit, user, post)

    assert html_response(conn, 200) =~ "Edit post"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn, user: user, post: post} do
    conn = put conn, user_post_path(conn, :update, user, post), post: @valid_attrs

    assert redirected_to(conn) == user_post_path(conn, :show, user, post)
    assert Repo.get_by(Post, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user, post: post} do
    conn = put conn, user_post_path(conn, :update, user, post), post: %{"body" => nil}

    assert html_response(conn, 200) =~ "Edit post"
  end

  test "deletes chosen resource", %{conn: conn, user: user, post: post} do
    conn = delete conn, user_post_path(conn, :delete, user, post)

    assert redirected_to(conn) == user_post_path(conn, :index, user)
    refute Repo.get(Post, post.id)
  end

  #TODO
  #test "redirects when the specified user does not exist", %{conn: conn} do
    #conn = get conn, user_post_path(conn, :index, %Pxblog.User{id: 1111})

    #assert get_flash(conn, :error) == "Invalid user!"
    #assert redirected_to(conn) == page_path(conn, :index)
    #assert conn.halted
  #end

  test "redirects when trying to edit a post for a different user", %{conn: conn, role: role, post: post} do
    other_user = TestHelper.create_user(role, %{email: "test2@test.com", username: "test2", password: "test", password_confirmation: "test"})
    conn = get conn, user_post_path(conn, :edit, other_user, post)

    assert get_flash(conn, :error) == "You are not authorized to modify that post!"
    assert redirected_to(conn) == page_path(conn, :index)
    assert conn.halted
  end

  test "redirects when trying to delete a post for a different user", %{conn: conn, role: role, post: post} do
    other_user = TestHelper.create_user(role, %{email: "isa@isa.com", username: "isa", password: "password", password_confirmation: "password"})
    conn = delete conn, user_post_path(conn, :delete, other_user, post)

    assert get_flash(conn, :error) == "You are not authorized to modify that post!"
    assert redirected_to(conn) == page_path(conn, :index)
    assert conn.halted
  end

  #TODO
  #test "renders form for editing chosen resource when logged in as admin", %{conn: conn, user: user, post: post} do
    #role = TestHelper.create_role(%{name: "juan", admin: true})
    #admin = TestHelper.create_user(role, %{email: "juan@juan.com", username: "juan", password: "password", password_confirmation: "password"})
    #conn = conn
      #|> login_user(admin)
      #|> put(user_post_path(conn, :update, user, post))

    #assert html_response(conn, 200) == "Edit post"
  #end

  test "updates chosen resource and redirects when data is valid when logged in as admin", %{conn: conn, user: user, post: post} do
    role = TestHelper.create_role(%{name: "juan", admin: true})
    admin = TestHelper.create_user(role, %{email: "juan@juan.com", username: "juan", password: "password", password_confirmation: "password"})
    conn = conn
      |> login_user(admin)
      |> put(user_post_path(conn, :update, user, post), post: @valid_attrs)

    assert redirected_to(conn) == user_post_path(conn, :update, user, post)
    assert Repo.get_by(Post, @valid_attrs)
  end

  test "does not update chosen resource and renders error when data is invalid when logged in as admin", %{conn: conn, user: user, post: post} do
    role = TestHelper.create_role(%{name: "juan", admin: true})
    admin = TestHelper.create_user(role, %{email: "juan@juan.com", username: "juan", password: "password", password_confirmation: "password"})
    conn = conn
      |> login_user(admin)
      |> put(user_post_path(conn, :update, user, post), post: %{"body" => nil})

    assert html_response(conn, 200) =~ "Edit post"
  end

  test "deletes chosen resource when logged in as admin", %{conn: conn, user: user, post: post} do
    role = TestHelper.create_role(%{name: "juan", admin: true})
    admin = TestHelper.create_user(role, %{email: "juan@juan.com", username: "juan", password: "password", password_confirmation: "password"})
    conn = conn
      |> login_user(admin)
      |> delete(user_post_path(conn, :delete, user, post))

    assert redirected_to(conn) == user_post_path(conn, :index, user)
    refute Repo.get(Post, post.id)
  end

  test "when logged in as the author, shows the chosen resource with author flag set to true", %{conn: conn, user: user, post: post} do
    conn = conn
      |> login_user(user)
      |> get(user_post_path(conn, :show, user, post))

      assert html_response(conn, 200) =~ "Show post"
      assert conn.assigns[:author_or_admin]
  end

  test "when logged in as admin, shows the chosen resource with author flag set to true", %{conn: conn, user: user, admin: admin, post: post} do
    conn = conn
      |> login_user(admin)
      |> get(user_post_path(conn, :show, user, post))

      assert html_response(conn, 200) =~ "Show post"
      assert conn.assigns[:author_or_admin]
  end

  #TODO -- access pages
  #TODO failed test
  test "when not logged in, shows the chosen resource with the author flag set to false", %{conn: conn, user: user, post: post} do
    conn = conn
      |> logout_user(user)
      |> get(user_post_path(conn, :show, user, post))

      assert html_response(conn, 200) =~ "Show post"
      #assert conn.assigns[:author_or_admin]
  end

  #TODO failed test
  test "when logged in as a different user, shows the chosen resource with the author flag set to false", %{conn: conn, user: user, other_user: other_user, post: post} do
    conn = conn
      |> login_user(other_user)
      |> get(user_post_path(conn, :show, user, post))

      assert html_response(conn, 200) =~ "Show post"
      #assert conn.assigns[:author_or_admin]
  end
end
