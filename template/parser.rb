require 'parslet'
require_relative 'number/parser'

class Template
  class Parser < Parslet::Parser
    rule(:empty) { str('') }
    rule(:backslash) { str('\\') }
    rule(:opening_bracket) { str('{') }
    rule(:closing_bracket) { str('}') }
    rule(:dot) { str('.') }
    rule(:double_quote) { str('"') }
    rule(:single_quote) { str("'") }
    rule(:backslash) { str('\\') }
    rule(:n) { str('n') }
    rule(:t) { str('t') }

    # string
    rule(:string_character) do
      opening_expression.absent? >> opening_interpolation.absent? >> any
    end
    rule(:escaped_string_character) do
      (backslash >> (n | t)) | (backslash.ignore >> any)
    end
    rule(:double_quote_string_character) do
      escaped_string_character | (double_quote.absent? >> string_character)
    end
    rule(:single_quote_string_character) do
      escaped_string_character | (single_quote.absent? >> string_character)
    end
    rule(:double_quote_string) do
      double_quote.ignore >>
        (
          (
            interpolation.as(:interpolation) | expression.as(:expression) |
              double_quote_string_character.repeat(1).as(:text)
          ).repeat(0)
        ) >> double_quote.ignore
    end
    rule(:single_quote_string) do
      single_quote.ignore >>
        (
          (
            interpolation.as(:interpolation) | expression.as(:expression) |
              single_quote_string_character.repeat(1).as(:text)
          ).repeat(0)
        ) >> single_quote.ignore
    end
    rule(:string) { double_quote_string | single_quote_string }

    # number
    rule(:number) { Template::Number::Parser.new }

    # name
    rule(:name_character) do
      opening_expression.absent? >> closing_expression.absent? >>
        opening_interpolation.absent? >> closing_interpolation.absent? >>
        operator.absent? >> any
    end
    rule(:name) { name_character.repeat(1) }

    # value
    rule(:value) { (number.as(:number) | string.as(:string) | name.as(:name)) }

    # operator
    rule(:operator_character) { dot }
    rule(:operator) { operator_character.repeat(1) }

    # statement
    rule(:statement) do
      (value.as(:value) >> operator.as(:operator) >> statement.as(:statement)) |
        value.as(:value)
    end
    rule(:statements) { statement.repeat(1) }

    # interpolation
    rule(:opening_interpolation) { opening_bracket >> opening_bracket }
    rule(:closing_interpolation) { closing_bracket >> closing_bracket }
    rule(:interpolation) do
      opening_interpolation.ignore >> statements >> closing_interpolation.ignore
    end

    # expression
    rule(:opening_expression) { opening_bracket }
    rule(:closing_expression) { closing_bracket }
    rule(:expression) do
      opening_expression.ignore >> statements >> closing_expression.ignore
    end

    # text
    rule(:unescaped_text_character) do
      opening_bracket.absent? >> closing_bracket.absent? >> any
    end
    rule(:escaped_text_character) { backslash.ignore >> any }
    rule(:text_character) { escaped_text_character | unescaped_text_character }
    rule(:text) { text_character.repeat(1) }

    rule(:template) do
      (
        interpolation.as(:interpolation) | expression.as(:expression) |
          text.as(:text)
      ).repeat(1) | empty.as(:text).repeat(1, 1)
    end

    root(:template)
  end
end
