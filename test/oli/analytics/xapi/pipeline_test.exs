defmodule Oli.Analytics.XAPI.PipelineTest do
  use Oli.DataCase

  alias Oli.Analytics.XAPI.UploadPipeline
  alias Oli.Analytics.XAPI.StatementBundle
  alias Oli.Analytics.XAPI.QueueProducer

  def make_bundle(data) do
    %StatementBundle{
      body: data,
      bundle_id: data,
      partition_id: data,
      category: :page_viewed,
      partition: :section
    }
  end

  describe "xapi upload pipeline tests" do
    setup do
      # Create the directory ./test_bundles
      File.mkdir_p!("./test_bundles")

      on_exit(fn ->
        File.rm_rf!("./test_bundles")
      end)

      map = Seeder.base_project_with_resource2()

      {:ok, map}
    end

    test "test pushing through a single message" do
      bundle = make_bundle("1")
      ref = Broadway.test_message(UploadPipeline, bundle)
      assert_receive {:ack, ^ref, [%{data: ^bundle}], []}

      assert File.exists?("./test_bundles/1.jsonl")
      assert File.read!("./test_bundles/1.jsonl") == "1"
    end

    test "test that failed uploads get written to DB" do
      bundle = make_bundle("fail")
      ref = Broadway.test_message(UploadPipeline, bundle)
      assert_receive {:ack, ^ref, [%{data: ^bundle}], []}

      refute File.exists?("./test_bundles/1.jsonl")
      [failed] = Oli.Repo.all(Oli.Analytics.XAPI.PendingUpload)

      assert failed.bundle["body"] == "fail"
      assert failed.reason == :failed

      # verify the QueueProducer.enqueue_from_storage reads and converts
      # to StatementBundle correctly
      [%StatementBundle{body: body}] = QueueProducer.enqueue_from_storage()
      assert body == "fail"
    end

    test "test that a single batcher honors batch keys" do
      bundle1a = make_bundle("1")
      bundle1b = make_bundle("1")
      bundle2a = make_bundle("2")
      bundle2b = make_bundle("2")

      ref = Broadway.test_batch(UploadPipeline, [bundle1a, bundle1b, bundle2a, bundle2b])
      assert_receive {:ack, ^ref, success, failure}, 1000

      # Verify that the two common messages were handled each in separate batches
      assert length(success) == 2
      assert length(failure) == 0

      # assert that ./test_bundles/1.jsonl and ./test_bundles/2.jsonl exist
      assert File.exists?("./test_bundles/1.jsonl")
      assert File.exists?("./test_bundles/2.jsonl")

      # verify that the contents of the files are correct, in other words
      # we verify that the two messages were coalesced into one file
      assert File.read!("./test_bundles/1.jsonl") == "1\n1"
      assert File.read!("./test_bundles/2.jsonl") == "2\n2"
    end

    test "verify that a stopped pipeline drains the QueueProducer" do
      Broadway.start_link(__MODULE__,
        name: :dummy_pipeline,
        producer: [
          module: {Oli.Analytics.XAPI.QueueProducer, []},
          transformer: {__MODULE__, :transform, []}
        ],
        processors: [
          default: [concurrency: 1, max_demand: 1]
        ],
        batchers: [
          default: [
            concurrency: 1,
            batch_size: 1
          ]
        ]
      )

      producer_name = Broadway.producer_names(:dummy_pipeline) |> hd

      # Async call to the producer
      GenStage.cast(producer_name, {:insert, make_bundle("1")})
      GenStage.cast(producer_name, {:insert, make_bundle("2")})

      # wait for the producer to receive the first message
      Process.sleep(100)

      # stop the pipeline, which should trigger the draining of the queue
      Broadway.stop(:dummy_pipeline)

      # verify that the QueueProducer was drained
      items = Oli.Repo.all(Oli.Analytics.XAPI.PendingUpload)
      assert length(items) == 1
    end
  end

  def transform(event, _opts) do
    %Broadway.Message{
      data: event,
      acknowledger: Broadway.NoopAcknowledger.init()
    }
  end

  def handle_message(_, %Broadway.Message{} = message, _) do
    # Simulate a stalled processer by sleeping for 2 seconds, which
    # will leave 1 item sitting in the producer queue
    Process.sleep(2_000)

    message
  end

  def handle_batch(:default, messages, _batch_info, _context) do
    messages
  end
end
