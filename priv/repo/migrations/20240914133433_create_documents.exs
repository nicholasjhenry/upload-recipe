defmodule UploadRecipe.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :name, :string
      add :filename, :string

      timestamps(type: :utc_datetime)
    end
  end
end
