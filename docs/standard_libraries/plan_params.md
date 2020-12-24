# PlanParams: a module for handling optional parameters passed to `Plans` and `Operations`

## Requirements
To add options to the plan, use a data association with the key `options` and a JSON-formatted value. This can be done in the **Designer** tab by clicking on **Plan Info** and **Add Data**. It can also be done with [Trident](https://github.com/klavinslab/trident) using the method `my_plan.associate("options", "{"my_option": 2.0}")`. 

Adding options to an `Operation` requires that the `OperationType` has an input parameter named `Options` that takes a JSON-formatted value. 

## Behavior
Optional parameters are divided into two groups: parameters that must be the same for all `Operations` in a `Job`, and parameters that can be different for different `Operations`. In code, the former are specified by including their keys in the `Hash` method `default_job_params` (see below), or any `Hash` that is passed to the `update_job_params` method. Before updating this `Hash`, the method will check that any keys in the `Hash` point to the same value in all `Operations`.

## Usage
You can demo this module using the following code snippets in Nemo:

```ruby
# Options Test Protocol
# Written By Devin Strickland <strcklnd@uw.edu> 2020-04-26

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'

class Protocol

  include PlanParams
  include Debug

  MY_DEBUG = true
  TEST_PARAMS = {
    who_is_on_first: false
  }

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations. 
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`. These inputs will override both 
  #     the defaults and any inputs that have been applied to the `Plan` ONLY IF
  #     all the values for a given key are the same for all `Operations` in 
  #     a `Job`. If non-matching params are detected, an exception will 
  #     be raised.
  #
  # @example "options": "{"my_option": 2.0}"
  def default_job_params
    {
      magic_number: 42,
      who_is_on_first: true
    }
  end

  # Default parameters that are applied to individual operations. 
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`. These inputs will override 
  #     the defaults. Operations options are accessed in the protocol using
  #     `op.temporary[:options]`. 
  #
  def default_operation_params
    {
      foo: 'bar'
    }
  end

  ########## MAIN ##########

  def main

    # Add TEST_PARAMS to the plan in test mode
    if debug && MY_DEBUG
      associate_plan_options(operations: operations, opts: TEST_PARAMS) 
    end

    # Check the initial state
    inspect default_job_params, 'default_job_params'
    inspect default_operation_params, 'default_operation_params'
    opts = operations.first.plan.associations[:options]
    inspect parse_options(opts), 'plan options'

    @job_params = {}

    begin
      @job_params = update_job_params(
        operations: operations, 
        default_job_params: default_job_params
      )
    rescue IncompatibleParametersError => e
      show do
        title 'Incompatible Parameters'
        warning e.message
      end

      operations.each { |op| op.error(:incompatible_parameters, e.message)}
      return {}
    end

    # Check the updated job_params
    inspect @job_params, 'final job_params'
    # Check the operation options
    operations.each_with_index do |op, i| 
      inspect op.input('Options').val, "Operation #{i+1} input options"
    end

    update_operation_params(
      operations: operations,
      default_operation_params: default_operation_params
    )

    # Check the updated operation options
    operations.each_with_index do |op, i|  
      inspect op.temporary[:options], "Operation #{i+1} final options"
    end

  end

end
```
```ruby
class ProtocolTest < ProtocolTestBase

  def setup

    add_operation
      .with_property("Options", '{ "magic_number": 24 }')

    add_operation
      .with_property("Options", '{ "magic_number": 24 }')

    add_operation
      .with_property("Options", '{ "magic_number": 24, "foo": "baz" }')

  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end

end
```
Running the above code yields:
# Test Results

All tests passed.

## Log
- Hello from Nemo

## Backtrace
---
---
## INSPECTING default_job_params (Hash)

{\"magic_number\":42,\"who_is_on_first\":true}

---
---
## INSPECTING default_operation_params (Hash)

{\"foo\":\"bar\"}

---
---
## INSPECTING plan options (Hash)

{\"who_is_on_first\":false}

---
---
## INSPECTING final job_params (Hash)

{\"magic_number\":24,\"who_is_on_first\":false}

---
---
## INSPECTING Operation 1 input options (Hash)

{\"magic_number\":24}

---
---
## INSPECTING Operation 2 input options (Hash)

{\"magic_number\":24}

---
---
## INSPECTING Operation 3 input options (Hash)

{\"magic_number\":24,\"foo\":\"baz\"}

---
---
## INSPECTING Operation 1 final options (Hash)

{\"foo\":\"bar\",\"magic_number\":24}

---
---
## INSPECTING Operation 2 final options (Hash)

{\"foo\":\"bar\",\"magic_number\":24}

---
---
## INSPECTING Operation 3 final options (Hash)

{\"foo\":\"baz\",\"magic_number\":24}

