require 'spec_helper'

RSpec.describe Template::Transform do
  let!(:source) { '' }
  subject do
    Template::Helpers.node_names(
      Template::Transform.new(Template::Parser.new.parse(source)).transform
    )
  end

  it { is_expected.to eq(['Text']) }

  context "with text" do
    let!(:source) { 'Hello world' }
    it { is_expected.to eq(['Text']) }
  end
end
