# frozen_string_literal: true

RSpec.shared_examples 'service ping payload with all expected metrics' do
  specify do
    allow(ApplicationRecord.database).to receive(:flavor).and_return(nil)

    aggregate_failures do
      expected_metrics.each do |metric|
        is_expected.to have_usage_metric metric['key_path']
      end
    end
  end
end
