<script>
import { mapGetters } from 'vuex';
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import BoardListHeaderFoss from '~/boards/components/board_list_header.vue';
import { n__, __, sprintf } from '~/locale';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';

export default {
  extends: BoardListHeaderFoss,
  inject: ['weightFeatureAvailable'],
  apollo: {
    boardList: {
      query: listQuery,
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      skip() {
        return this.isEpicBoard;
      },
    },
  },
  computed: {
    ...mapGetters(['isEpicBoard']),
    countIcon() {
      return this.isEpicBoard ? 'epic' : 'issues';
    },
    itemsCount() {
      return this.isEpicBoard ? this.list.epicsCount : this.boardList?.issuesCount;
    },
    itemsTooltipLabel() {
      const { maxIssueCount } = this.list;
      if (maxIssueCount > 0) {
        return sprintf(__('%{itemsCount} issues with a limit of %{maxIssueCount}'), {
          itemsCount: this.itemsCount,
          maxIssueCount,
        });
      }

      return this.isEpicBoard
        ? n__(`%d epic`, `%d epics`, this.itemsCount)
        : n__(`%d issue`, `%d issues`, this.itemsCount);
    },
    weightCountToolTip() {
      const { totalWeight } = this.boardList;

      if (this.weightFeatureAvailable) {
        return sprintf(__('%{totalWeight} total weight'), { totalWeight });
      }

      return null;
    },
  },
};
</script>
