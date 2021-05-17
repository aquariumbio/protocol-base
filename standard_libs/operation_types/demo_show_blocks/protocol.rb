# typed: false
# frozen_string_literal: true

needs 'Standard Libs/TestFixtures'

# Demo protocol for show block methods
#
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include TestFixtures

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    demo_array_argument

    # demo_include_show

    rval
  end

  def demo_array_argument
    ary = %w[Foo Bar Baz]

    show do
      title 'Array Arguments for Notes, Bullets, and Checks'

      note 'Notes'
      note ary
      separator
      note 'Bullets'
      bullet ary
      separator
      note 'Checks'
      check ary
    end
  end

  # TODO: This feature does not work as intended.
  def demo_include_show
    show do
      title 'Inserting Show Blocks Into Other Show Blocks'

      note 'Foo'
      insert included_show
    end
  end

  def included_show
    show do
      note 'Bar'
      note 'Baz'
    end
  end
end
