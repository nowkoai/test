# frozen_string_literal: true

require 'spec_helper'

describe Ci::Minutes::Notification do
  let_it_be(:user) { create(:user) }
  let(:shared_runners_enabled) { true }
  let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: shared_runners_enabled) }
  let_it_be(:group) { create(:group) }
  let(:injected_group) { group }
  let(:injected_project) { project }

  shared_examples 'queries for notifications' do
    context 'without limit' do
      it { is_expected.to be_falsey }
    end

    context 'when limit is defined' do
      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end
    end
  end

  shared_examples 'has notifications' do
    context 'when usage has reached a notification level' do
      before do
        group.shared_runners_minutes_limit = 20
      end

      context 'when at the warning level' do
        before do
          allow(group).to receive(:shared_runners_remaining_minutes).and_return(4)
        end

        it 'has warning notification' do
          expect(subject.show?).to be_truthy
          expect(subject.text).to match(/.*\shas 30% or less Shared Runner Pipeline minutes remaining/)
          expect(subject.style).to eq :warning
        end
      end

      context 'when at the danger level' do
        before do
          allow(group).to receive(:shared_runners_remaining_minutes).and_return(1)
        end

        it 'has danger notification' do
          expect(subject.show?).to be_truthy
          expect(subject.text).to match(/.*\shas 5% or less Shared Runner Pipeline minutes remaining/)
          expect(subject.style).to eq :danger
        end
      end

      context 'when right at the limit for notification' do
        before do
          allow(group).to receive(:shared_runners_remaining_minutes).and_return(6)
        end

        it 'has warning notification' do
          expect(subject.show?).to be_truthy
          expect(subject.text).to match(/.*\shas 30% or less Shared Runner Pipeline minutes remaining/)
          expect(subject.style).to eq :warning
        end
      end

      context 'when usage has exceeded the limit' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }

        it 'has exceeded notification' do
          expect(subject.show?).to be_truthy
          expect(subject.text).to match(/.*\shas exceeded its pipeline minutes quota/)
          expect(subject.style).to eq :danger
        end
      end
    end
  end

  shared_examples 'not eligible to see notifications' do
    before do
      group.shared_runners_minutes_limit = 10
      allow(group).to receive(:shared_runners_remaining_minutes).and_return(2)
    end

    context 'when not permitted to see notifications' do
      it 'has no notifications set' do
        expect(subject.show?).to be_falsey
        expect(subject.text).to be_nil
        expect(subject.style).to be_nil
      end
    end
  end

  context 'when at project level' do
    describe '#show?' do
      context 'when eligible to see notifications' do
        before do
          group.add_developer(user)
        end

        it_behaves_like 'queries for notifications' do
          subject do
            threshold = described_class.new(user, injected_project, nil)
            threshold.show?
          end
        end

        it_behaves_like 'has notifications' do
          subject { described_class.new(user, injected_project, nil) }
        end
      end

      it_behaves_like 'not eligible to see notifications' do
        subject { described_class.new(user, injected_project, nil) }
      end
    end
  end

  context 'when at namespace level' do
    describe '#show?' do
      context 'when eligible to see notifications' do
        let!(:user_pipeline) { create(:ci_pipeline, user: user, project: project) }

        context 'with a project that has runners enabled inside namespace' do
          it_behaves_like 'queries for notifications' do
            subject do
              threshold = described_class.new(user, nil, injected_group)
              threshold.show?
            end
          end

          it_behaves_like 'has notifications' do
            subject { described_class.new(user, nil, injected_group) }
          end
        end

        context 'with no projects that have runners enabled inside namespace' do
          it_behaves_like 'not eligible to see notifications' do
            let(:shared_runners_enabled) { false }
            subject { described_class.new(user, nil, injected_group) }
          end
        end
      end

      it_behaves_like 'not eligible to see notifications' do
        subject { described_class.new(user, nil, injected_group) }
      end
    end
  end
end
