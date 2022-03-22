require 'parslet'
require_relative 'number/parser'
require_relative 'helpers'

class Template
  class Parser < Parslet::Parser
    rule(:empty) { str('') }
    rule(:backslash) { str('\\') }
    rule(:left_curly_bracket) { str('{') }
    rule(:right_curly_bracket) { str('}') }
    rule(:left_square_bracket) { str('[') }
    rule(:right_square_bracket) { str(']') }
    rule(:left_parenthesis) { str('(') }
    rule(:right_parenthesis) { str(')') }
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
    rule(:define) { str('define') }
    rule(:end_keyword) { str('end') }
    rule(:if_keyword) { str('if') }

    # spaces
    rule(:space) { str(' ') }
    rule(:newline) { str("\n") }
    rule(:spaces) { (space | newline).repeat(1) }
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
          (code.as(:code) | double_quote_string_character.repeat(1).as(:text))
            .repeat(0)
        ) >> double_quote.ignore
    end
    rule(:single_quote_string) do
      single_quote.ignore >>
        (
          (code.as(:code) | single_quote_string_character.repeat(1).as(:text))
            .repeat(0)
        ) >> single_quote.ignore
    end
    rule(:short_string) { colon.ignore >> name }
    rule(:string) { double_quote_string | single_quote_string | short_string }

    # number
    rule(:number) { Template::Number::Parser.new }

    # name
    rule(:name_character) do
      left_curly_bracket.absent? >> right_curly_bracket.absent? >>
        left_square_bracket.absent? >> right_square_bracket.absent? >>
        left_parenthesis.absent? >> right_parenthesis.absent? >>
        colon.absent? >> comma.absent? >> operator.absent? >> space.absent? >>
        newline.absent? >> any
    end
    rule(:name) do
      define.absent? >> end_keyword.absent? >> if_keyword.absent? >>
        name_character.repeat(1)
    end

    # define arguments
    rule(:define_argument) do
      (name.as(:value) >> colon >> (spaces? >> value.as(:default)).maybe) |
        (
          value.as(:value) >>
            (spaces? >> equal >> spaces? >> value.as(:default)).maybe
        )
    end
    rule(:define_arguments) do
      left_parenthesis.ignore >> spaces?.ignore >>
        (
          define_argument.as(:first) >>
            (spaces? >> comma >> spaces? >> define_argument)
              .repeat(0)
              .as(:others)
        ).maybe >> spaces?.ignore >> right_parenthesis.ignore
    end

    # arguments
    rule(:call_argument) { implicit_dictionnary.as(:dictionnary) | value }
    rule(:call_arguments) do
      left_parenthesis.ignore >> spaces?.ignore >>
        (
          call_argument.as(:first) >>
            (spaces? >> comma >> spaces? >> call_argument).repeat(0).as(:others)
        ).maybe >> spaces?.ignore >> right_parenthesis.ignore
    end

    # call
    rule(:call) do
      name.as(:name) >>
        (operator.as(:operator) >> call.as(:call)).maybe >>
        call_arguments.as(:arguments).maybe
    end
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
      dictionnary.as(:dictionnary) | list.as(:list) | nothing.as(:nothing) |
        boolean.as(:boolean) | number.as(:number) | string.as(:string) |
        call.as(:call)
    end

    # operator
    rule(:operator) { dot | equal | greater_than }

    # statement
    rule(:define_statement) do
      define >> spaces >> name.as(:name) >>
        define_arguments.as(:arguments).maybe >>
        inner_statements.as(:body) >> end_keyword
    end
    rule(:if_statement) do
      if_keyword >> spaces >> statement.as(:if_statement) >>
        inner_statements.as(:if_body) >> end_keyword
    end
    rule(:value_statement) do
      implicit_dictionnary.as(:dictionnary) | implicit_list.as(:list) | value
    end
    rule(:statement) do
      (
        define_statement.as(:define) | if_statement.as(:if) | value_statement
      )
    end
    # "}Home{", " 1 "
    rule(:inner_statements) do
      (
        (right_curly_bracket >> template.as(:template) >> left_curly_bracket) |
        (space >> statement.repeat(1) >> space) |
        spaces.ignore
      )
    end
    rule(:statements) { statement.repeat(1) }

    # code
    rule(:code) do
      left_curly_bracket.ignore >> spaces?.ignore >> statements >>
        spaces?.ignore >> right_curly_bracket.ignore
    end

    # text
    rule(:unescaped_text_character) { left_curly_bracket.absent? >> any }
    rule(:escaped_text_character) { backslash.ignore >> any }
    rule(:text_character) { escaped_text_character | unescaped_text_character }
    rule(:text) { text_character.repeat(1) }

    # template
    rule(:template) do
      (code.as(:code) | text.as(:text)).repeat(1) | empty.as(:text).repeat(1, 1)
    end

    root(:template)
  end
end
