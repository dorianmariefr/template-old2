require_relative "../../template/parser"

RSpec.describe Template::Parser do
  let!(:template) { "" }
  subject { described_class.new.parse(template) }

  it { is_expected.to eq([{ text: "" }]) }

  context "with only text" do
    let!(:template) { "Hello" }
    it { is_expected.to eq([{ text: "Hello" }]) }
  end

  context "with an interpolation" do
    let!(:template) { "Hello {{user.first_name}}" }
    it {
      is_expected.to eq([
        { text: "Hello " },
        {
          interpolation: [
            {
              value: { name: "user" },
              operator: ".",
              statement: { value: { name: "first_name" } }
            }
          ]
        }
      ])
    }
  end

  context "with an escaped interpolation" do
    let!(:template) { "Hello \\{\\{user.first_name\\}\\}" }
    it {
      is_expected.to eq([
        { text: "Hello {{user.first_name}}" },
      ])
    }
  end

  context "with an expression" do
    let!(:template) { "{users.pop}" }
    it {
      is_expected.to eq([
        {
          expression: [
            {
              value: { name: "users" },
              operator: ".",
              statement: { value: { name: "pop" } }
            }
          ]
        }
      ])
    }
  end

  context "strings" do
    context "double quote" do
      let!(:template) { '{"Hello"}' }

      it {
        is_expected.to eq([
          {
            expression: [
              {
                value: { string: "Hello" },
              }
            ]
          }
        ])
      }
    end

    context "single quote" do
      let!(:template) { "{'Hello'}" }

      it {
        is_expected.to eq([
          {
            expression: [
              {
                value: { string: "Hello" },
              }
            ]
          }
        ])
      }
    end

    context "escaped characters" do
      let!(:template) { "{'Dorian\\'s\\nOr not'}" }

      it {
        is_expected.to eq([
          {
            expression: [
              {
                value: { string: "Dorian's\\nOr not" },
              }
            ]
          }
        ])
      }
    end
  end
end
