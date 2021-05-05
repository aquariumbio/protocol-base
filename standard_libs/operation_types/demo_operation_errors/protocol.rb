# typed: false
# frozen_string_literal: true

needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/OperationErrors'

class Protocol
  include TestFixtures
  include OperationErrors

  def main
    show do
      note "The job starts with #{operations.running.length} operations."
    end

    msg = "Game over for this operation!"
    operations.first.error(:input_error, msg)
    report_errors

    show do
      note "The job continues with #{operations.running.length} operations."
    end

    msg = "All your operations are belong to us!"
    operations.running.first.error(:input_error, msg)
    report_errors(abort_job: true)
    return {} if operations.errored.any?

    show do
      note 'This block is unreachable.'
    end

    {}
  end
end
