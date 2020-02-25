# frozen_string_literal: true

module Spree
  module Core
    module NumberGeneratorDecorator
      NUMBER_LENGTH  = 9
      NUMBER_LETTERS = false
      NUMBER_PREFIX  = 'N'

      def generate_number(options = {})
        options[:length]  ||= NUMBER_LENGTH
        options[:letters] ||= NUMBER_LETTERS
        options[:prefix]  ||= NUMBER_PREFIX

        possible = (0..9).to_a
        possible += ('A'..'Z').to_a if options[:letters]

        self.number ||= loop do
          # Make a random number.
          random = (0...options[:length]).map { possible.sample }.join.to_s
          # make sure that first element is not zero
          random[0] = (1..9).to_a.sample.to_s
          random = options[:prefix] + random
          # Use the random  number if no other order exists with it.
          if self.class.exists?(number: random)
            # If over half of all possible options are taken add another digit.
            if self.class.count > (10**options[:length] / 2)
              options[:length] += 1
            end
          else
            break random
          end
        end
      end
    end
  end
end

Spree::Core::NumberGenerator.prepend(Spree::Core::NumberGeneratorDecorator)
