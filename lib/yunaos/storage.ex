defmodule Yunaos.Storage do
  @moduledoc """
  S3-compatible object storage interface backed by ExAws.
  Uses MinIO in development and any S3-compatible service in production.
  """

  def bucket do
    Application.fetch_env!(:yunaos, :s3)[:bucket]
  end

  def upload(path, content, opts \\ []) do
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    bucket()
    |> ExAws.S3.put_object(path, content, content_type: content_type)
    |> ExAws.request()
  end

  def download(path) do
    bucket()
    |> ExAws.S3.get_object(path)
    |> ExAws.request()
  end

  def delete(path) do
    bucket()
    |> ExAws.S3.delete_object(path)
    |> ExAws.request()
  end

  def presigned_url(path, opts \\ []) do
    ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, bucket(), path, opts)
  end

  def list(prefix \\ "") do
    bucket()
    |> ExAws.S3.list_objects(prefix: prefix)
    |> ExAws.request()
  end

  def ensure_bucket! do
    case ExAws.S3.head_bucket(bucket()) |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, _} ->
        bucket()
        |> ExAws.S3.put_bucket("us-east-1")
        |> ExAws.request()
    end
  end
end
