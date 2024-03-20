defmodule RecordingConverter.Compositor do
  @moduledoc false

  @output_width 1280
  @output_height 720
  @video_output_id "video_output_1"
  @audio_output_id "audio_output_1"

  @spec server_setup(binary) :: :start_locally | {:start_locally, String.t()}
  def server_setup(compositor_path) do
    compositor_path = compositor_path

    if is_nil(compositor_path) do
      :start_locally
    else
      {:start_locally, compositor_path}
    end
  end

  @spec scene(any()) :: map()
  def scene(children) do
    %{
      id: "tiles_0",
      type: :tiles,
      width: @output_width,
      height: @output_height,
      background_color_rgba: "#00000000",
      children: children
    }
  end

  @spec audio_output_id() :: String.t()
  def audio_output_id(), do: @audio_output_id

  @spec video_output_id() :: String.t()
  def video_output_id(), do: @video_output_id

  @spec generate_output_update(String.t(), list(), number()) :: tuple()
  def generate_output_update("video", video_tracks, timestamp) when is_list(video_tracks) do
    {
      :lc_request,
      %{
        type: :update_output,
        output_id: @video_output_id,
        video:
          video_tracks
          |> Enum.map(&%{type: :input_stream, input_id: &1.id})
          |> scene(),
        schedule_time_ms: from_ns_to_ms(timestamp)
      }
    }
  end

  def generate_output_update("audio", audio_tracks, timestamp) when is_list(audio_tracks) do
    {
      :lc_request,
      %{
        type: :update_output,
        output_id: @audio_output_id,
        audio: %{
          inputs: Enum.map(audio_tracks, &%{input_id: &1.id})
        },
        schedule_time_ms: from_ns_to_ms(timestamp)
      }
    }
  end

  @spec schedule_unregister_video_output(number()) :: {:lc_request, map()}
  def schedule_unregister_video_output(schedule_time_ns),
    do: {
      :lc_request,
      %{
        type: :unregister,
        entity_type: :output_stream,
        output_id: @video_output_id,
        schedule_time_ms: from_ns_to_ms(schedule_time_ns)
      }
    }

  @spec schedule_unregister_audio_output(number()) :: {:lc_request, map()}
  def schedule_unregister_audio_output(schedule_time_ns),
    do: {
      :lc_request,
      %{
        type: :unregister,
        entity_type: :output_stream,
        output_id: @audio_output_id,
        schedule_time_ms: from_ns_to_ms(schedule_time_ns)
      }
    }

  @spec schedule_unregister_input(number(), binary()) :: {:lc_request, map()}
  def schedule_unregister_input(schedule_time_ns, input_id),
    do: {
      :lc_request,
      %{
        type: :unregister,
        entity_type: :input_stream,
        input_id: input_id,
        schedule_time_ms: from_ns_to_ms(schedule_time_ns)
      }
    }

  defp from_ns_to_ms(timestamp_ns) do
    rounded_ts =
      timestamp_ns |> Membrane.Time.nanoseconds() |> Membrane.Time.as_milliseconds(:round)

    max(0, rounded_ts - 10)
  end
end
