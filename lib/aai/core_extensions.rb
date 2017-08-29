module Aai
  module CoreExtensions
    module Time
      def date_and_time fmt="%F %T.%L"
        Object::Time.now.strftime fmt
      end

      def time_it title="", logger=nil, run: true
        if run
          t = Object::Time.now

          yield

          time = Object::Time.now - t

          if title == ""
            msg = "Finished in #{time} seconds"
          else
            msg = "#{title} finished in #{time} seconds"
          end

          if logger
            logger.info msg
          else
            $stderr.puts msg
          end
        end
      end
    end

    module Process
      include CoreExtensions::Time

      def run_it *a, &b
        exit_status, stdout, stderr = systemu *a, &b

        puts stdout unless stdout.empty?
        $stderr.puts stderr unless stderr.empty?

        exit_status
      end

      def run_it! *a, &b
        exit_status = self.run_it *a, &b

        # Sometimes, exited? is not true and there will be no exit
        # status. Success should catch all failures.
        AbortIf.abort_unless exit_status.success?,
                             "Command failed with status " +
                             "'#{exit_status.to_s}' " +
                             "when running '#{a.inspect}', " +
                             "'#{b.inspect}'"

        exit_status
      end

      # Examples
      #
      # Process.extend CoreExtensions::Process
      # Time.extend CoreExtensions::Time
      #
      # Process.run_and_time_it! "Saying hello",
      #                          %Q{echo "hello world"}
      #
      # Process.run_and_time_it! "This will raise SystemExit",
      #                          "ls arstoeiarntoairnt" do
      #   puts "i like pie"
      # end
      def run_and_time_it! title="",
                           cmd="",
                           logger=AbortIf::logger,
                           &b

        AbortIf.logger.debug { "Running: #{cmd}" }

        time_it title, logger do
          run_it! cmd, &b
        end
      end
    end
  end
end
