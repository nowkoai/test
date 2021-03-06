# frozen_string_literal: true

class Analytics::CycleAnalytics::Aggregation < ApplicationRecord
  include FromUnion

  belongs_to :group, optional: false

  validates :incremental_runtimes_in_seconds, :incremental_processed_records, :last_full_run_runtimes_in_seconds, :last_full_run_processed_records, presence: true, length: { maximum: 10 }, allow_blank: true

  scope :priority_order, -> { order('last_incremental_run_at ASC NULLS FIRST') }
  scope :enabled, -> { where('enabled IS TRUE') }

  def self.safe_create_for_group(group)
    top_level_group = group.root_ancestor
    return if Analytics::CycleAnalytics::Aggregation.exists?(group_id: top_level_group.id)

    insert({ group_id: top_level_group.id }, unique_by: :group_id)
  end

  def self.load_batch(last_run_at, batch_size = 100)
    last_run_at_not_set = Analytics::CycleAnalytics::Aggregation
      .enabled
      .where(last_incremental_run_at: nil)
      .priority_order
      .limit(batch_size)

    last_run_at_before = Analytics::CycleAnalytics::Aggregation
      .enabled
      .where('last_incremental_run_at < ?', last_run_at)
      .priority_order
      .limit(batch_size)

    Analytics::CycleAnalytics::Aggregation
      .from_union([last_run_at_not_set, last_run_at_before], remove_order: false, remove_duplicates: false)
      .limit(batch_size)
  end
end
