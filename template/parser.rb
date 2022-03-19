require 'parslet'
require_relative 'number/parser'

class Template
  class Parser < Parslet::Parser
    rule(:empty) { str('') }
    rule(:backslash) { str('\\') }
    rule(:left_curly_bracket) { str('{') }
    rule(:right_curly_bracket) { str('}') }
    rule(:left_square_bracket) { str('[') }
    rule(:right_square_bracket) { str(']') }
    rule(:dot) { str('.') }
    rule(:double_quote) { str('"') }
    rule(:single_quote) { str("'") }
    rule(:backslash) { str('\\') }
    rule(:comma) { str(',') }
    rule(:colon) { str(':') }
    rule(:equal) { str('=') }
    rule(:greater_than) { str('>') }
    rule(:n) { str('n') }
    rule(:t) { str('t') }

    # spaces
    rule(:spaces) { match('\s').repeat(1) }
    rule(:spaces?) { spaces.maybe }

    # string
    rule(:string_character) { left_curly_bracket.absent? >> any }
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
      left_curly_bracket.absent? >> right_curly_bracket.absent? >>
        left_square_bracket.absent? >> right_square_bracket.absent? >>
        colon.absent? >> comma.absent? >> operator.absent? >> spaces.absent? >>
        any
    end
    rule(:name) { name_character.repeat(1) }

    # boolean
    rule(:boolean) { str('true') | str('false') }

    # nothing
    rule(:nothing) { str('nothing') }

    # list
    rule(:list_value) { implicit_dictionnary.as(:dictionnary) | value }
    rule(:implicit_list) do
      value.as(:first) >> spaces? >> comma >>
        (
          spaces? >> list_value.as(:second) >>
            (comma >> spaces? >> list_value).repeat(0).as(:others)
        ).maybe
    end
    rule(:list) do
      left_square_bracket >> spaces? >> list_value.as(:first) >>
      (comma >> spaces? >> list_value).repeat(0).as(:others) >> spaces? >>
        right_square_bracket
    end

    # dictionnary
    rule(:short_key) { name.as(:string) >> colon }
    rule(:long_key) { value >> spaces? >> (colon | (equal >> greater_than)) }
    rule(:key_value) do
      (short_key | long_key).as(:key) >> spaces? >> value.as(:value)
    end
    rule(:implicit_dictionnary) do
      key_value.as(:first) >>
        (spaces? >> comma >> spaces? >> key_value).repeat(0).as(:others)
    end
    rule(:dictionnary) do
      left_curly_bracket >> spaces? >> key_value.as(:first) >>
        (comma >> spaces? >> key_value).repeat(0).as(:others) >> spaces? >>
        right_curly_bracket
    end

    # value
    rule(:value) do
      dictionnary.as(:dictionnary) | list.as(:list) |
      nothing.as(:nothing) | boolean.as(:boolean) | number.as(:number) |
        string.as(:string) | name.as(:name)
    end

    # operator
    rule(:operator) { dot | equal | greater_than }

    # statement
    rule(:statement) do
      (value >> operator.as(:operator) >> statement.as(:statement)) |
        (implicit_dictionnary.as(:dictionnary) | implicit_list.as(:list) | value)
    end
    rule(:statements) { statement.repeat(1) }

    # interpolation
    rule(:opening_interpolation) { left_curly_bracket >> equal }
    rule(:closing_interpolation) { right_curly_bracket }
    rule(:interpolation) do
      opening_interpolation.ignore >> spaces?.ignore >> statements >>
        spaces?.ignore >> closing_interpolation.ignore
    end

    # expression
    rule(:opening_expression) { left_curly_bracket }
    rule(:closing_expression) { right_curly_bracket }
    rule(:expression) do
      opening_expression.ignore >> spaces?.ignore >> statements >>
        spaces?.ignore >> closing_expression.ignore
    end

    # text
    rule(:unescaped_text_character) do
      left_curly_bracket.absent? >> right_curly_bracket.absent? >> any
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
