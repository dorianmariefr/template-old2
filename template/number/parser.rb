require 'parslet'

class Template
  class Number
    # 12,735.23 is parsed as { base_10: { whole: '12735', decimal: '23' } }
    class Parser < Parslet::Parser
      rule(:minus) { str('-') }
      rule(:plus) { str('+') }
      rule(:dot) { str('.') }
      rule(:underscore) { str('_') }
      rule(:comma) { str(',') }
      rule(:e) { str('e') }
      rule(:zero) { str('0') }
      rule(:one) { str('1') }
      rule(:two) { str('2') }
      rule(:three) { str('3') }
      rule(:four) { str('4') }
      rule(:five) { str('5') }
      rule(:six) { str('6') }
      rule(:seven) { str('7') }
      rule(:eight) { str('8') }
      rule(:nine) { str('9') }
      rule(:a) { str('a') | str('A') }
      rule(:b) { str('b') | str('B') }
      rule(:c) { str('c') | str('C') }
      rule(:d) { str('d') | str('D') }
      rule(:e) { str('e') | str('E') }
      rule(:f) { str('f') | str('F') }
      rule(:x) { str('x') | str('X') }
      rule(:o) { str('o') | str('O') }
      rule(:b) { str('b') | str('b') }

      # space
      rule(:space) { match('\s') }

      # infinity
      rule(:infinity) do
        str('Infinity') | str('infinity') | str('INFINITY') | str('♾')
      end

      # base 16
      rule(:base_16_digit) do
        zero | one | two | three | four | five | six | seven | eight | nine |
          a | b | c | d | e | f
      end
      rule(:base_16_number) do
        zero.ignore >> x.ignore >> base_16_digit.repeat(1)
      end

      # base 8
      rule(:base_8_digit) do
        zero | one | two | three | four | five | six | seven
      end
      rule(:base_8_number) { zero.ignore >> o.ignore >> base_8_digit.repeat(1) }

      # base 2
      rule(:base_2_digit) { zero | one }
      rule(:base_2_number) { zero.ignore >> b.ignore >> base_2_digit.repeat(1) }

      # base 10
      rule(:base_10_digit) do
        zero | one | two | three | four | five | six | seven | eight | nine
      end
      rule(:base_10_number) do
        (base_10_digit | space.ignore | underscore.ignore | comma.ignore)
          .repeat(1)
          .as(:whole) >>
          (
            dot.ignore >>
              (base_10_digit | space.ignore | underscore.ignore).repeat(1)
          ).as(:decimal).maybe >>
          (e.ignore >> base_10_number).as(:exponent).maybe
      end

      rule(:number) do
        (minus | plus).as(:sign).maybe >>
          (
            infinity.as(:infinity) | base_16_number.as(:base_16) |
              base_8_number.as(:base_8) | base_2_number.as(:base_2) |
              base_10_number.as(:base_10)
          )
      end
      root(:number)
    end
  end
end
