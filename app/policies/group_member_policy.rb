# frozen_string_literal: true

class GroupMemberPolicy < BasePolicy
  delegate :group

  with_scope :subject
  condition(:last_owner) { @subject.group.member_last_owner?(@subject) || @subject.group.member_last_blocked_owner?(@subject) }
  condition(:project_bot) { @subject.user&.project_bot? && @subject.group.member?(@subject.user) }

  desc "Membership is users' own"
  with_score 0
  condition(:is_target_user) { @user && @subject.user_id == @user.id }

  rule { anonymous }.policy do
    prevent :update_group_member
    prevent :destroy_group_member
  end

  rule { last_owner }.policy do
    prevent :update_group_member
    prevent :destroy_group_member
  end

  rule { ~project_bot & can?(:admin_group_member) }.policy do
    enable :update_group_member
    enable :destroy_group_member
  end

  rule { project_bot & can?(:admin_group_member) }.enable :destroy_project_bot_member

  rule { is_target_user }.policy do
    enable :destroy_group_member
  end
end

GroupMemberPolicy.prepend_mod_with('GroupMemberPolicy')
