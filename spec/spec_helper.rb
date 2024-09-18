# frozen_string_literal: true

require "ar_virtual_field"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.dirname(__FILE__) + '/db/test.db'
)

class ClassDataWraper
  def table(&block)
    @table ||= block
  end

  def model(&block)
    @model ||= block
  end
end

def suppress_output
  begin
    original_stderr = $stderr.clone
    original_stdout = $stdout.clone
    $stderr.reopen(File.new('/dev/null', 'w'))
    $stdout.reopen(File.new('/dev/null', 'w'))
    retval = yield
  rescue Exception => e
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
    raise e
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end
  retval
end

def model_with_table(klass_name, &definition)
  table_name = klass_name.tableize

  class_data = ClassDataWraper.new
  class_data.instance_eval(&definition)

  before(:all) do
    suppress_output do
      ActiveRecord::Migration.create_table(table_name, force: true, &class_data.table)
    end

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = table_name
      class_eval(&class_data.model)
    end

    Object.const_set(klass_name, klass)
  end

  after(:all) do
    Object.send(:remove_const, klass_name)
  end
end
