defmodule FunkAndSchuster.FileService do
  alias FunkAndSchuster.FileService.FileInfo
  alias FunkAndSchuster.Repo

  # Read

  def get_file_by_filename(filename) when is_binary(filename),
    do: Repo.get_by(FileInfo, filename: filename)

  # Upload

  def upload_file(%Plug.Upload{} = upload) do
    upload
    |> FileInfo.changeset()
    |> Repo.insert()
  end

  def upload_file(nil), do: {:error, :no_file}

  def upload_file!(%Plug.Upload{} = upload) do
    upload
    |> FileInfo.changeset()
    |> Repo.insert!()
  end

  def batch_upload_files!(uploads) when is_list(uploads),
    do: Enum.map(uploads, &upload_file!/1)

  # Delete

  def delete_file(%FileInfo{} = file), do: Repo.delete(file)

  def delete_file(filename) when is_binary(filename) do
    filename
    |> Repo.get_by(FileInfo, filename: filename)
    |> case do
      nil -> {:error, :not_found}
      %FileInfo{} = file_info -> Repo.delete(file_info)
    end
  end

  def delete_file!(%FileInfo{} = file), do: Repo.delete!(file)

  def delete_file!(filename) when is_binary(filename) do
    filename
    |> Repo.get_by!(FileInfo, filename: filename)
    |> Repo.delete!()
  end

  def batch_delete_files!(files) when is_list(files),
    do: Enum.map(files, &delete_file!/1)
end
