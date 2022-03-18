require 'parslet'

class Template
  class Number
    # 12,735.23 is parsed as 12735.23
    class Parser < Parslet::Parser
      rule(:minus) { str('-') }
      rule(:plus) { str('+') }
      rule(:dot) { str('.') }
      rule(:underscore) { str('_') }
      rule(:comma) { str(',') }
      rule(:e) { str('e') }
      rule(:infinity) { str('Infinity') | str('infinity') | str('♾') }

      # space
      rule(:space) { match('\s') }

      # base 10
      rule(:base_10_digit) { match['0-9'] }
      rule(:base_10_number) do
        (
          base_10_digit |
            space.ignore |
            underscore.ignore |
            comma.ignore
        ).repeat(1).as(:whole) >> (
          dot.ignore >> (
            base_10_digit |
              space.ignore |
              underscore.ignore
          ).repeat(1)
        ).as(:decimal).maybe >> (
          e.ignore >> base_10_number
        ).as(:exponent).maybe
      end

      rule(:number) do
        (minus | plus).as(:sign).maybe >> (
          infinity.as(:infinity) |
          #base_16_number.as(:base_16) |
          base_10_number.as(:base_10) #|
          #base_8_number.as(:base_8) |
          #base_2_number.as(:base_2)
        )
      end
      root(:number)
    end
  end
end
