RSpec.describe Loggun::Formatter do
  describe 'call' do
    let!(:severity) { nil }
    let!(:time) { DateTime.now }
    let!(:program_name) { nil }
    let!(:message) { nil }

    subject { described_class.new.call(severity, time, program_name, message) }

    context 'when a pattern contains only time and message' do
      let!(:message) { 'message' }
      let!(:timestamp) { '2020-02-11T11:53:26.186+05:00' }
      let!(:time) { DateTime.parse(timestamp) }

      before do
        Loggun::Config.instance.pattern = '%{time} %{message}'
        Loggun::Config.instance.precision = :ms
        Loggun::Config.instance.log_format = :plain
        Loggun::Config.instance.force_utc = false
      end

      it 'returns correct string' do
        expect(subject).to eq("#{timestamp} #{message}\n")
      end
    end

    context 'when :utc time format' do
      let!(:timestamp) { '2020-02-11T06:53:26.186Z' }
      let!(:time) { DateTime.parse(timestamp) }

      before do
        Loggun::Config.instance.pattern = '%{time}'
        Loggun::Config.instance.precision = :ms
        Loggun::Config.instance.force_utc = true
      end

      it 'returns correct string' do
        expect(subject).to eq("#{timestamp}\n")
      end
    end

    context 'when :json log format' do
      let!(:message) { 'message' }
      let!(:timestamp) { '2020-02-11T11:53:26.186+05:00' }
      let!(:time) { DateTime.parse(timestamp) }

      before do
        Loggun::Config.instance.precision = :ms
        Loggun::Config.instance.log_format = :json
        Loggun::Config.instance.force_utc = false
      end

      context 'when exclude_keys and only_keys are empty' do
        it 'returns correct string' do
          log = JSON.parse(subject)
          expect(log['timestamp']).to eq(timestamp)
          expect(log['message']).to eq(message)
          expect(log['severity']).to eq('INFO')
          expect(log['tags_text']).to eq(nil)
          expect(log['type']).to eq('-')
          expect(log['transaction_id']).to eq(nil)
        end
      end

      context 'when exclude_keys is not empty' do
        before do
          Loggun::Config.instance.exclude_keys = %i[pid severity tags_text transaction_id]
        end

        it 'returns correct string' do
          expect(subject).to eq("{\"timestamp\":\"#{timestamp}\",\"message\":\"#{message}\",\"type\":\"-\"}\n")
        end
      end

      context 'when only_keys is not empty' do
        before do
          Loggun::Config.instance.only_keys = %i[timestamp message]
        end

        it 'returns correct string' do
          expect(subject.to_s).to eq("{\"timestamp\":\"#{timestamp}\",\"message\":\"#{message}\"}\n".to_s)
        end
      end
    end
  end
end