RSpec.describe Loggun::Config do
  describe 'configure' do
    before do
      Singleton.send :__init__, described_class
    end

    let!(:instance) { described_class.instance }
    let!(:timestamp_precision) { %i[micros microseconds us].sample }
    let!(:number_precision) { 6 }
    let!(:pattern) { '%{time} %{message}' }

    subject do
      described_class.configure do |config|
        config.timestamp_precision = timestamp_precision
        config.pattern = pattern
      end
    end

    context 'pass all configs' do
      it 'set configs' do
        subject

        expect(instance.timestamp_precision).to eq(number_precision)
        expect(instance.pattern).to eq(pattern)
      end
    end
  end
end
