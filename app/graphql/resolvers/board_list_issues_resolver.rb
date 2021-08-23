# frozen_string_literal: true

module Resolvers
  class BoardListIssuesResolver < BaseResolver
    include BoardItemFilterable

    argument :filters, Types::Boards::BoardIssueInputType,
             required: false,
             description: 'Filters applied when selecting issues in the board list.'

    type Types::IssueType, null: true

    alias_method :list, :object

    def resolve(**args)
      filter_params = item_filters(args[:filters]).merge(board_id: list.board.id, id: list.id)
      service = ::Boards::Issues::ListService.new(list.board.resource_parent, context[:current_user], filter_params)
      pagination_connections = Gitlab::Graphql::Pagination::Keyset::Connection.new(service.execute)

      initialize_relative_positions(pagination_connections.items, list.board)

      pagination_connections
    end

    def initialize_relative_positions(issues, board)
      if Gitlab::Database.read_write? && !board.disabled_for?(current_user)
        Issue.move_nulls_to_end(issues)
      end
    end

    # https://gitlab.com/gitlab-org/gitlab/-/issues/235681
    def self.complexity_multiplier(args)
      0.005
    end
  end
end
