require_relative 'rails_helper'

RSpec.describe Rails do
  it 'has default formatter' do
    expect(described_class.logger.formatter.class)
      .to eq(ActiveSupport::Logger::SimpleFormatter)
  end
end