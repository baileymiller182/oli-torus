defmodule OliWeb.Delivery.Student.Learn.Components.LearningModule do
  use OliWeb, :live_component

  alias OliWeb.Delivery.Student.Utils

  def update(assigns, socket) do

    progress = parse_student_progress_for_resource(
      assigns.student_progress_per_resource_id,
      assigns.learning_module["resource_id"]
    )

    socket = assign(socket,
      id: assigns.id,
      learning_module: assigns.learning_module,
      progress: progress,
      student_progress_per_resource_id: assigns.student_progress_per_resource_id
    )
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={assigns.id} tabindex="0" class="module bg-white rounded-lg py-2 px-6 shadow-shadowed my-2">

      <.activity_info
        learning_module={assigns.learning_module}
        progress={parse_student_progress_for_resource(
          assigns.student_progress_per_resource_id,
          assigns.learning_module["resource_id"]
        )}
        myself={@myself}
      />
    </div>
    """
  end

  defp parse_minutes(minutes) when minutes in ["", nil], do: "?"
  defp parse_minutes(minutes), do: minutes

  defp activity_info(assigns) do
    ~H"""
      <div class="flex flex-row items-center">
        <h1 class="text-lg font-bold tracking-tight text-slate-800">
          <%= "Module #{assigns.learning_module["numbering"]["index"]}" %>
        </h1>
        <h1 class="mx-2 text-sm">•</h1>
        <h1 class="font-medium mr-auto tracking-tight text-slate-400 text-sm">
          <%= assigns.learning_module["title"] %>
        </h1>
        <div class="text-right dark:text-white opacity-60 whitespace-nowrap">
          <span class="text-sm font-semibold font-['Open Sans']" role="duration in minutes">
            <%= parse_minutes(assigns.learning_module["duration_minutes"]) %>
            <span class="w-[25px] self-stretch text-[13px] font-semibold font-['Open Sans']">
              min
            </span>
          </span>
        </div>
        <.activity_bar
          label="Time"
          percent={assigns.progress}
          color="bg-[#a855f7]"
          textcolor="text-[#a855f7]"
        />
        <.activity_bar
          label="Learning"
          percent={assigns.progress}
          color="bg-[#06b6d4]"
          textcolor="text-[#06b6d4]"
        />
        <.activity_bar
          label="Practice"
          percent={assigns.progress}
          color="bg-[#34d399]"
          textcolor="text-[#34d399]"
        />
        <.activity_bar
          label="Assessment"
          percent={assigns.progress}
          color="bg-[#f97316]"
          textcolor="text-[#f97316]"
        />
        <button
          phx-click="select_module"
          phx-target={@myself}
        >
          <div class={"w-8 h-[36px] py-2.5 px-2.5 justify-center items-center flex gap-2.5 -rotate-90"}>
            <.chevron_icon />
          </div>
        </button>
      </div>
    """
  end

  def handle_event("select_module", %{"slug" => _} = values, socket),
    do: navigate_to_resource(values, socket)

  def navigate_to_resource(values, socket) do
    section_slug = socket.assigns.section.slug
    resource_id = values["resource_id"] || values["module_resource_id"]
    selected_view = values["view"] || :gallery

    {:noreply,
     push_redirect(socket,
       to:
         resource_url(
           values["slug"],
           section_slug,
           resource_id,
           selected_view
         )
     )}
  end

  defp resource_url(resource_slug, section_slug, resource_id, selected_view) do
    Utils.lesson_live_path(
      section_slug,
      resource_slug,
      request_path:
        Utils.learn_live_path(section_slug,
          target_resource_id: resource_id,
          selected_view: selected_view
        ),
      selected_view: selected_view
    )
  end

  defp parse_student_progress_for_resource(student_progress_per_resource_id, resource_id) do
    Map.get(student_progress_per_resource_id, resource_id, 0.0)
    |> Kernel.*(100)
    |> format_float()
  end

  defp format_float(float) do
    float
    |> round()
    |> trunc()
  end

  defp chevron_icon(assigns) do
    ~H"""
    <svg width="14" height="9" viewBox="0 0 14 9" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M1 1.5L7 7.5L13 1.5"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="stroke-black/60 dark:stroke-white"
      />
    </svg>
    """
  end

end
