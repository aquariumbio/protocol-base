# OperationErrors provides methods for dealing with operations that
#   are errored out during a Job
#
module OperationErrors
  # Creates and displays a table of all Operations that are errored
  # @todo Make it so that associations that are not errors are not listed\
  #
  def report_errors(abort_job: false)
    return unless operations.errored.present?

    error_table = [['Operation ID', 'Error', 'Message']]

    operations.errored.each do |op|
      op.associations.each do |k, v|
        error_table << [op.id, k, v]
      end
    end

    show do
      title 'Some Operations Have Errors'
      note 'Some rows may not represent error conditions, but each Operation ' \
              'listed has at least one fatal error.'
      table error_table
      if abort_job
        warning 'This Job will terminate early. Please abort it manually if it does not.'
      else
        warning 'Consult with the lab manager about whether to abort this Job.'
      end
    end
  end
end
