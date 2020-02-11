RSpec.describe Loggun::Config do
  describe 'configure' do
    before do
      Singleton.send :__init__, described_class
    end

    let!(:instance) { described_class.instance }
    let!(:precision) { %i[micros microseconds us].sample }
    let!(:pattern) { '%{time} %{message}' }

    subject do
      described_class.configure do |config|
        config.precision = precision
        config.pattern = pattern
      end
    end

    context 'pass all configs' do
      it 'set configs' do
        subject

        expect(instance.precision).to eq(precision)
        expect(instance.pattern).to eq(pattern)
      end
    end
  end
end
