defmodule UploadRecipe.DocumentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `UploadRecipe.Documents` context.
  """

  @doc """
  Generate a document.
  """
  def document_fixture(attrs \\ %{}) do
    {:ok, document} =
      attrs
      |> Enum.into(%{
        filename: "some filename",
        name: "some name"
      })
      |> UploadRecipe.Documents.create_document()

    document
  end
end
