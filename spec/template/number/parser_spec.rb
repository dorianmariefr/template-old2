require "spec_helper"

RSpec.describe Template::Number::Parser do
  let!(:number) { '0' }

  subject do
    described_class.new.parse(number)
  rescue Parslet::ParseFailed => e
    puts e.parse_failure_cause.ascii_tree
    raise e
  end

  it { is_expected.to eq(base_10: { whole: '0' }) }

  context 'base 10' do
    context 'multiple digits' do
      let!(:number) { '123' }
      it { is_expected.to eq(base_10: { whole: '123' }) }
    end

    context 'with spaces' do
      let!(:number) { '12 345 678' }
      it { is_expected.to eq(base_10: { whole: '12345678' }) }
    end

    context 'with commas' do
      let!(:number) { '12,345,678' }
      it { is_expected.to eq(base_10: { whole: '12345678' }) }
    end

    context 'with decimal part' do
      let!(:number) { '12.34' }
      it { is_expected.to eq(base_10: { whole: '12', decimal: '34' }) }
    end

    context 'with an exponent' do
      let!(:number) { '1e10' }
      it { is_expected.to eq(base_10: { whole: '1', exponent: '10' }) }
    end

    context 'with a minus sign' do
      let!(:number) { '-20' }
      it { is_expected.to eq(sign: '-', base_10: { whole: '20' }) }
    end
  end

  context 'base 16' do
    let!(:number) { '0xFF' }
    it { is_expected.to eq(base_16: 'FF') }
  end

  context 'base 8' do
    let!(:number) { '0o17' }
    it { is_expected.to eq(base_8: '17') }
  end

  context 'base 2' do
    let!(:number) { '0b10' }
    it { is_expected.to eq(base_2: '10') }
  end
end
