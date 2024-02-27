defmodule Oli.Analytics.ByPage do
  import Ecto.Query, warn: false
  alias Oli.Delivery.Sections.SectionResource
  alias Oli.Delivery.Snapshots.Snapshot
  alias Oli.Repo
  alias Oli.Analytics.Common
  alias Oli.Publishing
  alias Oli.Authoring.Course.Project

  def query_against_project_slug(project_slug, filtered_sections) do
    base_query = get_base_query(project_slug, get_activity_pages(project_slug))

    case filtered_sections do
      [] -> base_query
      _filtered_sections -> get_query_with_join_filter(base_query, filtered_sections)
    end
    |> Repo.all()
  end

  defp get_query_with_join_filter(query, filter_list) do
    from page in query,
      join: resource in assoc(page, :resource),
      left_join: section_resource in SectionResource,
      on: resource.id == section_resource.resource_id,
      where: section_resource.section_id in ^filter_list
  end

  defp get_base_query(project_slug, activity_pages) do
    from(
      page in subquery(Publishing.query_unpublished_revisions_by_type(project_slug, "page")),
      left_join: pairing in subquery(activity_pages),
      on: page.resource_id == pairing.page_id,
      left_join:
        activity in subquery(
          Publishing.query_unpublished_revisions_by_type(project_slug, "activity")
        ),
      on: pairing.activity_id == activity.resource_id,
      left_join: analytics in subquery(Common.analytics_by_activity(project_slug)),
      on: pairing.activity_id == analytics.activity_id,
      select: %{
        slice: page,
        activity: activity,
        eventually_correct: analytics.eventually_correct,
        first_try_correct: analytics.first_try_correct,
        number_of_attempts: analytics.number_of_attempts,
        relative_difficulty: analytics.relative_difficulty
      },
      preload: [:resource_type]
    )
  end

  defp get_activity_pages(project_slug) do
    from(project in Project,
      where: project.slug == ^project_slug,
      join: snapshot in Snapshot,
      on: snapshot.project_id == project.id,
      group_by: [snapshot.activity_id, snapshot.resource_id],
      select: %{
        activity_id: snapshot.activity_id,
        page_id: snapshot.resource_id
      }
    )
  end
end
