defmodule OliWeb.Delivery.Student.Learn.Components.Week do
  use OliWeb, :live_component

  def update(assigns, socket) do
    duration = Enum.reduce(assigns.unit["children"], 0, fn child, acc ->
      acc + child["duration_minutes"]
    end)

    progress = parse_student_progress_for_resource(
      assigns.student_progress_per_resource_id,
      assigns.unit["resource_id"]
    )

    socket = assign(socket,
      id: assigns.id,
      duration: duration,
      unit: assigns.unit,
      student_progress_per_resource_id: assigns.student_progress_per_resource_id,
      expanded: assigns.expanded,
      progress: progress,
      section: assigns.section
    )
    {:ok, socket}
  end

  def render(%{expanded: false} = assigns) do
    ~H"""
      <div id={assigns.id} tabindex="0" class="rounded-lg px-8 shadow-shadowed">
        <.activity_info
            unit={assigns.unit}
            progress={assigns.progress}
            myself={@myself}
            expanded={assigns.expanded}
            duration={assigns.duration}
        />
      </div>
      """
  end

  def render(%{expanded: true} = assigns) do
    ~H"""
      <div id={@id} tabindex="0" class="rounded-lg px-8 shadow-shadowed mb-4">
        <.activity_info
            unit={assigns.unit}
            progress={assigns.progress}
            myself={@myself}
            expanded={assigns.expanded}
            duration={assigns.duration}
        />
        <div class="flex flex-row">
          <div class="flex flex-col w-full border-l border-stone-200 pl-6">
              <.live_component
                :for={learning_module <- assigns.unit["children"]}
                id={"module" <> Integer.to_string(learning_module["resource_id"])}
                module={OliWeb.Delivery.Student.Learn.Components.LearningModule},
                learning_module={learning_module}
                student_progress_per_resource_id={assigns.student_progress_per_resource_id}
                section={assigns.section}
              />
          </div>
        </div>
      </div>
      """
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

  def handle_event("toggle_chevron", _value, socket) do
    new_expanded =
      case socket.assigns.expanded do
        false -> true
        true -> false
      end

    {:noreply, assign(socket, :expanded, new_expanded)}
  end

  defp parse_minutes(minutes) when minutes in ["", nil], do: "?"
  defp parse_minutes(minutes), do: minutes

  defp activity_info(assigns) do
    ~H"""
      <div class="flex flex-row items-center bg-white p-4 my-4">
        <h1 class="text-lg font-bold tracking-tight text-slate-800">
          <%= "Week #{assigns.unit["numbering"]["index"]}" %>
        </h1>
        <h1 class="mx-2 text-sm">•</h1>
        <h1 class="font-medium mr-auto tracking-tight text-slate-400 text-sm">
          <%= assigns.unit["title"] %>
        </h1>
        <div class="text-right dark:text-white opacity-60 whitespace-nowrap">
          <span class="text-sm font-semibold font-['Open Sans']" role="duration in minutes">
            <%= parse_minutes(assigns.duration) %>
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
        <button phx-click="toggle_chevron" phx-target={@myself} >
          <div class={"w-8 h-[36px] py-2.5 px-2.5 justify-center items-center flex gap-2.5 #{if assigns.expanded, do: "rotate-180", else: ""}"}>
            <.chevron_icon />
          </div>
        </button>
      </div>
    """
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
