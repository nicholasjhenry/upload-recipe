defmodule UploadRecipe.Repo do
  use Ecto.Repo,
    otp_app: :upload_recipe,
    adapter: Ecto.Adapters.Postgres
end
