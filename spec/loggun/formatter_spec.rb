RSpec.describe Loggun::Formatter do
  describe 'call' do
    let!(:severity) { nil }
    let!(:time) { DateTime.now }
    let!(:program_name) { nil }
    let!(:message) { nil }

    subject { described_class.new.call(severity, time, program_name, message) }

    context 'when a pattern contains only time and message' do
      let!(:message) { 'message' }
      let!(:timestamp) { '2020-02-11T06:53:26.186Z' }
      let!(:time) { DateTime.parse(timestamp) }

      before do
        Loggun::Config.instance.pattern = '%{time} %{message}'
        Loggun::Config.instance.precision = :ms
        Loggun::Config.instance.log_format = :custom
      end

      it 'returns correct string' do
        expect(subject).to eq("#{timestamp} #{message}\n")
      end
    end
  end
end