require_relative '../../template/parser'

RSpec.describe Template::Parser do
  let!(:template) { '' }
  subject do
    described_class.new.parse(template)
  rescue Parslet::ParseFailed => e
    puts e.parse_failure_cause.ascii_tree
    raise e
  end

  it { is_expected.to eq([{ text: '' }]) }

  context 'with only text' do
    let!(:template) { 'Hello' }
    it { is_expected.to eq([{ text: 'Hello' }]) }
  end

  context 'nothing' do
    let!(:template) { '{nothing}' }
    it { is_expected.to eq([{ expression: [{ value: { nothing: "nothing" } }] }]) }
  end

  context "boolean" do
    context 'true' do
      let!(:template) { '{true}' }
      it { is_expected.to eq([{ expression: [{ value: { boolean: "true" } }] }]) }
    end

    context 'false' do
      let!(:template) { '{false}' }
      it { is_expected.to eq([{ expression: [{ value: { boolean: "false" } }] }]) }
    end
  end

  context 'with an interpolation' do
    let!(:template) { 'Hello {{user.first_name}}' }
    it do
      is_expected.to eq(
        [
          { text: 'Hello ' },
          {
            interpolation: [
              {
                value: {
                  name: 'user'
                },
                operator: '.',
                statement: {
                  value: {
                    name: 'first_name'
                  }
                }
              }
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
              {
                value: {
                  name: 'users'
                },
                operator: '.',
                statement: {
                  value: {
                    name: 'pop'
                  }
                }
              }
            ]
          }
        ]
      )
    end
  end

  context 'strings' do
    def matches_string(string)
      is_expected.to eq(
        [{ expression: [{ value: { string: [{ text: string }] } }] }]
      )
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
      let!(:template) { '{"Hello {{user}}"}' }

      it do
        is_expected.to eq(
          [
            {
              expression: [
                {
                  value: {
                    string: [
                      { text: 'Hello ' },
                      { interpolation: [{ value: { name: 'user' } }] }
                    ]
                  }
                }
              ]
            }
          ]
        )
      end
    end
  end
end
