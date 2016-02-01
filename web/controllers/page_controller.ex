defmodule OrionMedia.PageController do
  use OrionMedia.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", files: (media_files |> IO.inspect)
  end

  def show(conn, %{"filename" => filename}) do
    load_video(conn, filename)
  end

  defp media_files do
    media_dir = "priv/static/media"
    {:ok, files} = File.ls(media_dir)
    filetype = [".mp4", ".mp3"]
    
    Enum.filter(files, fn(file) -> 
      String.ends_with?(file, filetype)
    end)
    |> Enum.map(fn(file) -> 
      %{filename: file} 
    end)
  end

  def load_video(conn, filename) do 
    video_path = "priv/static/media/#{filename}"
    {:ok, stats} = File.stat(video_path)
    filesize = stats.size

    [range_start, range_end] =
      if Enum.empty?(Plug.Conn.get_req_header(conn, "range")) do
        [0, filesize - 1]
      else
        [rn] = Plug.Conn.get_req_header(conn, "range")

        res = Regex.run(~r/bytes=([0-9]+)-([0-9])?/, rn)
        default_end = Integer.to_string(filesize - 2)

        {range_start, _} = res |> Enum.at(1) |> Integer.parse
        {range_end, _} = res |> Enum.at(2, default_end) |> Integer.parse

        [range_start, range_end]
      end

    content_length = range_end - range_start + 2
    conn
      |> Plug.Conn.put_resp_content_type("audio/mp4")
      |> Plug.Conn.put_resp_header("content-length", Integer.to_string(content_length))
      |> Plug.Conn.put_resp_header("accept-ranges", "bytes")
      |> Plug.Conn.put_resp_header("content-disposition", ~s(inline; filename="#{filename}"))
      |> Plug.Conn.put_resp_header("content-range", "bytes #{range_start}-#{range_end}/#{filesize}")
      |> Plug.Conn.send_file(206, video_path, range_start, content_length)
  end
end

# http://stackoverflow.com/questions/33204076/ranged-response-flow-in-phoenix-elixir