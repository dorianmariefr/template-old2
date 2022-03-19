require_relative '../../template/parser'

RSpec.describe Template::Parser do
  let!(:template) { '' }

  subject do
    described_class.new.parse(template)
  rescue Parslet::ParseFailed => e
    puts e.parse_failure_cause.ascii_tree
    raise e
  end

  def matches_expression(expression)
    is_expected.to eq([{ expression: [expression] }])
  end

  it { is_expected.to eq([{ text: '' }]) }

  context 'with only text' do
    let!(:template) { 'Hello' }
    it { is_expected.to eq([{ text: 'Hello' }]) }
  end

  context 'nothing' do
    let!(:template) { '{nothing}' }
    it { matches_expression(nothing: 'nothing') }
  end

  context 'boolean' do
    context 'true' do
      let!(:template) { '{true}' }
      it { matches_expression(boolean: 'true') }
    end

    context 'false' do
      let!(:template) { '{false}' }
      it { matches_expression(boolean: 'false') }
    end
  end

  context 'with an interpolation' do
    let!(:template) { 'Hello {=user.first_name}' }
    it do
      is_expected.to eq(
        [
          { text: 'Hello ' },
          {
            interpolation: [
              { name: 'user', operator: '.', statement: { name: 'first_name' } }
            ]
          }
        ]
      )
    end
  end

  context 'with an escaped interpolation' do
    let!(:template) { "Hello \\{\\{user.first_name\\}\\}" }
    it { is_expected.to eq([{ text: 'Hello {{user.first_name}}' }]) }
  end

  context 'with an expression' do
    let!(:template) { '{users.pop}' }
    it do
      is_expected.to eq(
        [
          {
            expression: [
              { name: 'users', operator: '.', statement: { name: 'pop' } }
            ]
          }
        ]
      )
    end
  end

  context 'strings' do
    def matches_string(string)
      is_expected.to eq([{ expression: [{ string: [{ text: string }] }] }])
    end

    context 'double quote' do
      let!(:template) { '{"Hello"}' }
      it { matches_string('Hello') }
    end

    context 'single quote' do
      let!(:template) { "{'Hello'}" }
      it { matches_string('Hello') }
    end

    context 'escaped characters' do
      let!(:template) { "{'Dorian\\'s\\nOr not'}" }
      it { matches_string("Dorian's\\nOr not") }
    end

    context 'interpolation' do
      let!(:template) { '{"Hello {=user}"}' }

      it do
        matches_expression(
          string: [{ text: 'Hello ' }, { interpolation: [{ name: 'user' }] }]
        )
      end
    end
  end

  context 'lists' do
    context 'explicit list' do
      let!(:template) { '{[true, false, nothing]}' }

      it do
        matches_expression(
          list: {
            first: {
              boolean: 'true'
            },
            others: [{ boolean: 'false' }, { nothing: 'nothing' }]
          }
        )
      end
    end

    context 'implicit list' do
      let!(:template) { '{true, false, nothing}' }

      it do
        matches_expression(
          list: {
            first: {
              boolean: 'true'
            },
            second: {
              boolean: 'false'
            },
            others: [{ nothing: 'nothing' }]
          }
        )
      end
    end

    context 'nested list' do
      let!(:template) { '{true, [false, true], nothing}' }

      it do
        matches_expression(
          list: {
            first: {
              boolean: 'true'
            },
            second: {
              list: {
                first: {
                  boolean: 'false'
                },
                others: [{ boolean: 'true' }]
              }
            },
            others: [{ nothing: 'nothing' }]
          }
        )
      end
    end
  end

  context 'dictionnaries' do
    context 'explicit dictionnary with single key value pair' do
      let!(:template) { '{{name: "Dorian"}}' }

      it do
        matches_expression(
          dictionnary: {
            first: {
              key: {
                string: 'name'
              },
              value: {
                string: [{ text: 'Dorian' }]
              }
            },
            others: []
          }
        )
      end
    end

    context 'explicit dictionnary with multiple key value pairs' do
      let!(:template) { '{{name: "Dorian", twitter: "@dorianmariefr"}}' }

      it do
        matches_expression(
          dictionnary: {
            first: {
              key: {
                string: 'name'
              },
              value: {
                string: [{ text: 'Dorian' }]
              }
            },
            others: [
              {
                key: {
                  string: 'twitter'
                },
                value: {
                  string: [{ text: '@dorianmariefr' }]
                }
              }
            ]
          }
        )
      end
    end
  end
end
