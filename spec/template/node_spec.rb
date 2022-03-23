require 'spec_helper'

RSpec.describe Template::Node do
  let!(:source) { '' }

  describe "#to_s" do
    let!(:context) { {} }

    subject { Template::Node::Template.parse(source).to_s(**context) }

    it { is_expected.to eq('') }

    context 'text' do
      let!(:source) { 'Hello world' }
      it { is_expected.to eq('Hello world') }
    end

    context 'code' do
      let!(:source) { 'Hello {name}' }

      it { is_expected.to eq('Hello ') }

      context "with name defined" do
        let!(:context) { { name: "Dorian" } }
        it { is_expected.to eq('Hello Dorian') }
      end
    end
  end

  describe "#to_h" do
    subject { Template::Node::Template.parse(source).to_h }

    it { is_expected.to eq([{ value: '' }]) }

    context 'text' do
      let!(:source) { 'Hello world' }

      it { is_expected.to eq([{ value: 'Hello world' }]) }
    end

    context 'code' do
      let!(:source) { 'Hello {name}' }

      it do
        is_expected.to eq([{ value: 'Hello ' }, [{ name: { value: 'name' } }]])
      end
    end

    context 'if, statement, and code' do
      let!(:source) { '{if item.parent}{render(item.parent)}{end}' }

      it do
        is_expected.to eq(
          [
            [
              {
                if_body: [
                  [
                    {
                      arguments: [
                        {
                          call: {
                            name: {
                              value: 'parent'
                            }
                          },
                          name: {
                            value: 'item'
                          },
                          operator: {
                            value: '.'
                          }
                        }
                      ],
                      name: {
                        value: 'render'
                      }
                    }
                  ]
                ],
                if_statement: {
                  call: {
                    name: {
                      value: 'parent'
                    }
                  },
                  name: {
                    value: 'item'
                  },
                  operator: {
                    value: '.'
                  }
                }
              }
            ]
          ]
        )
      end
    end

    context 'real world template' do
      let!(:source) { <<~TEMPLATE }
        {define render(item)}
          <p>{link_to(item.user.name, item.user.url)}</p>

          {markdown(item.content)}

          <p>{link_to(item.created_at.to_formatted_s(:long), item.url)}</p>

          {if item.parent}
            {render(item.parent)}
          {end}
        {end}

        {render(item)}
        TEMPLATE

      it { expect { subject }.to_not raise_error }
    end
  end
end
