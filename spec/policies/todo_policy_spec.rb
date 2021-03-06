# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodoPolicy do
  let_it_be(:author) { create(:user) }

  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let_it_be(:todo1) { create(:todo, author: author, user: user1, issue: issue) }
  let_it_be(:todo2) { create(:todo, author: author, user: user2, issue: issue) }
  let_it_be(:todo3) { create(:todo, author: author, user: user2) }
  let_it_be(:todo4) { create(:todo, author: author, user: user3, issue: issue) }

  def permissions(user, todo)
    described_class.new(user, todo)
  end

  before_all do
    project.add_developer(user1)
    project.add_developer(user2)
  end

  describe 'own_todo' do
    it 'allows owners to access their own todos if they can read todo target' do
      [
        [user1, todo1],
        [user2, todo2]
      ].each do |user, todo|
        expect(permissions(user, todo)).to be_allowed(:read_todo)
      end
    end

    it 'does not allow users to access todos of other users' do
      [
        [user1, todo2],
        [user1, todo3],
        [user2, todo1],
        [user2, todo4],
        [user3, todo1],
        [user3, todo2],
        [user3, todo3],
        [user2, todo3],
        [user3, todo4]
      ].each do |user, todo|
        expect(permissions(user, todo)).to be_disallowed(:read_todo)
      end
    end
  end
end
