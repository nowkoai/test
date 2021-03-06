# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of epic boards' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list1) { create(:epic_list, epic_board: board) }
  let_it_be(:list2) { create(:epic_list, epic_board: board, list_type: :closed) }
  let_it_be(:list3) { create(:epic_list, epic_board: board, list_type: :backlog) }

  let(:fields) { all_graphql_fields_for('epic_lists'.classify) }

  def pagination_query(params = {})
    graphql_query_for(:group, { full_path: group.full_path },
      <<~BOARDS
        epicBoard(id: "#{board.to_global_id}") {
          #{query_nodes(:lists, fields, include_pagination_info: true, args: params)}
        }
      BOARDS
    )
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when the user does not have access to the epic board group' do
    it 'returns nil group' do
      post_graphql(pagination_query, current_user: current_user)

      expect(graphql_data['group']).to be_nil
    end
  end

  context 'when user can access the epic board group' do
    before do
      group.add_developer(current_user)
    end

    describe 'sorting and pagination' do
      let(:data_path) { [:group, :epicBoard, :lists] }
      let(:all_records) { [list3.to_global_id.to_s, list1.to_global_id.to_s, list2.to_global_id.to_s] }

      def pagination_results_data(nodes)
        nodes.map { |list| list['id'] }
      end

      it_behaves_like 'sorted paginated query' do
        # currently we don't support custom sorting for epic lists,
        # nil value will be ignored by ::Graphql::Arguments
        let(:sort_param) { nil }
        let(:first_param) { 2 }
      end
    end

    it 'avoids N+1 queries' do
      list1.update_preferences_for(current_user, collapsed: true)

      control = ActiveRecord::QueryRecorder.new { post_graphql(pagination_query, current_user: current_user) }

      list2.update_preferences_for(current_user, collapsed: true)

      expect { post_graphql(pagination_query, current_user: current_user) }.not_to exceed_query_limit(control)
    end

    describe 'field values' do
      let_it_be(:other_user) { create(:user) }

      it 'returns the correct values for collapsed' do
        list1.update_preferences_for(current_user, collapsed: true)
        list1.update_preferences_for(other_user, collapsed: false)

        post_graphql(pagination_query, current_user: current_user)

        # ordered by list_type then position - backlog first and closed last.
        assert_field_value('id', [global_id_of(list3), global_id_of(list1), global_id_of(list2)])
        assert_field_value('collapsed', [false, true, false])
      end

      it 'returns the correct metadata values' do
        label = create(:group_label, group: group)
        # Epics in backlog, the list which is returned first. The first epic
        # should be ignored because it doesn't have the label by which we are
        # filtering.
        create(:labeled_epic, group: group)
        create(:labeled_epic, group: group, labels: [label], confidential: true)
        epic_with_issue = create(:labeled_epic, group: group, labels: [label])

        create(:issue, project: project, epic: epic_with_issue, weight: 3)
        create(:issue, project: project, epic: epic_with_issue, weight: 4)

        params = { epicFilters: { labelName: label.title, confidential: false } }
        post_graphql(pagination_query(params), current_user: current_user)

        assert_field_value('epicsCount', [1, 0, 0])
        expected_metadata = [
          { 'epicsCount' => 1, 'totalWeight' => 7 },
          { 'epicsCount' => 0, 'totalWeight' => nil },
          { 'epicsCount' => 0, 'totalWeight' => nil }
        ]
        assert_field_value('metadata', expected_metadata)
      end

      context 'when totalWeight not requested' do
        let(:fields) { "metadata { epicsCount }" }

        it 'does not required the value from the service' do
          post_graphql(pagination_query, current_user: current_user)

          expect(dig_data('metadata').first.keys).to match_array(['epicsCount'])
        end
      end
    end
  end

  def assert_field_value(field, expected_value)
    expect(dig_data(field)).to eq(expected_value)
  end

  def dig_data(field)
    graphql_dig_at(graphql_data, 'group', 'epicBoard', 'lists', 'nodes', field)
  end
end
