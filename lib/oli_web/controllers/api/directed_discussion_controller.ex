# API to support getting collaborative space discussions into the directed discussion activity.

defmodule OliWeb.Api.DirectedDiscussionController do
  @moduledoc """
  Provides user state service endpoints for extrinsic state.
  """
  use OliWeb, :controller
  use OpenApiSpex.Controller

  alias Oli.Repo
  alias Oli.Delivery.Sections

  alias Oli.Resources.Collaboration
  alias OliWeb.Api.State

  def create_post(conn, %{"resource_id" => resource_id, "section_slug" => section_slug}) do
    content = conn.body_params["content"]
    parent_post_id = Map.get(conn.body_params, "parent_post_id", nil)
    current_user = Map.get(conn.assigns, :current_user)
    section = Sections.get_section_by_slug(section_slug)

    Collaboration.create_post(%{
      :status => :approved,
      :user_id => current_user.id,
      :section_id => section.id,
      :resource_id => resource_id,
      :parent_post_id => parent_post_id,
      :thread_root_id => parent_post_id,
      :replies_count => 0,
      :anonymous => false,
      :content => %{"message" => content}
    })
    |> preload_post_user
    |> case do
      {:ok, post} ->
        json(conn, %{
          "result" => "success",
          "post" => post_response(post)
        })

      error ->
        json(conn, %{
          "result" => "failure",
          "error" => error
        })
    end
  end

  defp preload_post_user(post) do
    case post do
      {:ok, post} -> {:ok, Repo.preload(post, :user)}
      error -> error
    end
  end

  def get_discussion(conn, %{"resource_id" => resource_id, "section_slug" => section_slug}) do
    section = Sections.get_section_by_slug(section_slug)
    current_user = Map.get(conn.assigns, :current_user)

    posts =
      Collaboration.list_posts_for_user_in_page_section(
        section.id,
        resource_id,
        current_user.id
      )
      |> Enum.map(&post_response/1)

    json(conn, %{
      "result" => "success",
      "resource" => resource_id,
      "section" => section_slug,
      "posts" => posts
    })
  end

  defp post_response(post) do
    %{
      id: post.id,
      content: post.content.message,
      user_id: post.user_id,
      user_name: post.user.name,
      parent_post_id: post.parent_post_id,
      thread_root_id: post.thread_root_id,
      replies_count: post.replies_count,
      anonymous: post.anonymous,
      updated_at: post.updated_at
    }
  end
end
