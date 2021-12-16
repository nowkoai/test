# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ComplianceManagement::Violations::ApprovedByMergeRequestAuthor do
  let_it_be(:author) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, state: :merged, author: author) }

  subject(:violation) { described_class.new(merge_request) }

  describe '#execute' do
    shared_examples 'violation' do
      it 'creates a ComplianceViolation', :aggregate_failures do
        expect { execute }.to change { merge_request.compliance_violations.count }.by(1)

        violations = merge_request.compliance_violations.where(reason: described_class::REASON)

        expect(violations.map(&:violating_user)).to contain_exactly(author)
      end
    end

    subject(:execute) { violation.execute }

    context 'when merge request is approved by someone other than the author' do
      before do
        merge_request.approver_users << create(:user)
      end

      it 'does not create a ComplianceViolation' do
        expect { execute }.not_to change(MergeRequests::ComplianceViolation, :count)
      end

      context 'when merge request is also approved by the author' do
        before do
          merge_request.approver_users << author
        end

        it_behaves_like 'violation'
      end
    end

    context 'when merge request is approved by its author' do
      before do
        merge_request.approver_users << author
      end

      it_behaves_like 'violation'
    end
  end
end
