defmodule UploadRecipeWeb.DocumentLive.FormComponent do
  use UploadRecipeWeb, :live_component

  alias UploadRecipe.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage document records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="document-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />

        <.live_file_input upload={@uploads.file} />
        <section phx-drop-target={@uploads.file.ref}>
          <%!-- render each file entry --%>
          <%= for entry <- @uploads.file.entries do %>
            <article class="upload-entry">
              <figure>
                <%!-- <.live_img_preview entry={entry} /> --%>
                <figcaption><%= entry.client_name %></figcaption>
              </figure>
              <%!-- entry.progress will update automatically for in-flight entries --%>
              <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
              <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
              <button
                type="button"
                phx-target={@myself}
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
              >
                &times;
              </button>
              <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
              <%= for err <- upload_errors(@uploads.file, entry) do %>
                <p class="alert alert-danger"><%= error_to_string(err) %></p>
              <% end %>
            </article>
          <% end %>
          <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
          <%= for err <- upload_errors(@uploads.file) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        </section>

        <:actions>
          <.button phx-disable-with="Saving...">Save Document</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{document: document} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:file, accept: ~w(.pdf), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(Documents.change_document(document))
     end)}
  end

  @impl true
  def handle_event("validate", %{"document" => document_params}, socket) do
    changeset = Documents.change_document(socket.assigns.document, document_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"document" => document_params}, socket) do
    [uploaded_file] = upload_files(socket, ".pdf")
    document_params = Map.put(document_params, "filename", uploaded_file)
    save_document(socket, socket.assigns.action, document_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  defp upload_files(socket, extension) do
    consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
      filename =
        Enum.join([
          Path.basename(entry.client_name, extension),
          "-",
          Ecto.UUID.generate(),
          extension
        ])

      dest = Path.join(Application.app_dir(:upload_recipe, "priv/static/uploads"), filename)

      # You will need to create `priv/static/uploads` for `File.cp!/2` to work.
      File.cp!(path, dest)
      {:ok, filename}
    end)
  end

  defp save_document(socket, :edit, document_params) do
    case Documents.update_document(socket.assigns.document, document_params) do
      {:ok, document} ->
        notify_parent({:saved, document})

        {:noreply,
         socket
         |> put_flash(:info, "Document updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_document(socket, :new, document_params) do
    case Documents.create_document(document_params) do
      {:ok, document} ->
        notify_parent({:saved, document})

        {:noreply,
         socket
         |> put_flash(:info, "Document created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
