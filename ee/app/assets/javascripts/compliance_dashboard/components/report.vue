<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlLink, GlKeysetPagination } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__, __ } from '~/locale';
import { thWidthClass, sortObjectToString, sortStringToObject } from '~/lib/utils/table_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import complianceViolationsQuery from '../graphql/compliance_violations.query.graphql';
import { mapViolations } from '../graphql/mappers';
import { DEFAULT_SORT, GRAPHQL_PAGE_SIZE } from '../constants';
import { parseViolationsQueryFilter } from '../utils';
import MergeCommitsExportButton from './merge_requests/merge_commits_export_button.vue';
import MergeRequestDrawer from './drawer.vue';
import ViolationReason from './violations/reason.vue';
import ViolationFilter from './violations/filter.vue';

export default {
  name: 'ComplianceReport',
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTable,
    GlLink,
    GlKeysetPagination,
    MergeCommitsExportButton,
    MergeRequestDrawer,
    ViolationReason,
    SeverityBadge,
    TimeAgoTooltip,
    ViolationFilter,
    UrlSync,
  },
  props: {
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    groupPath: {
      type: String,
      required: true,
    },
    defaultQuery: {
      type: Object,
      required: true,
    },
  },
  data() {
    const sortParam = this.defaultQuery.sort || DEFAULT_SORT;
    const { sortBy, sortDesc } = sortStringToObject(sortParam);

    return {
      urlQuery: { ...this.defaultQuery },
      queryError: false,
      violations: {
        list: [],
        pageInfo: {},
      },
      showDrawer: false,
      drawerMergeRequest: {},
      drawerProject: {},
      sortBy,
      sortDesc,
      sortParam,
      paginationCursors: {
        before: null,
        after: null,
      },
    };
  },
  apollo: {
    violations: {
      query: complianceViolationsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
          filter: parseViolationsQueryFilter(this.urlQuery),
          sort: this.sortParam,
          first: GRAPHQL_PAGE_SIZE,
          ...this.paginationCursors,
        };
      },
      update(data) {
        const { nodes, pageInfo } = data?.group?.mergeRequestViolations || {};
        return {
          list: mapViolations(nodes),
          pageInfo,
        };
      },
      error(e) {
        Sentry.captureException(e);
        this.queryError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.violations.loading;
    },
    hasMergeCommitsCsvExportPath() {
      return this.mergeCommitsCsvExportPath !== '';
    },
    showPagination() {
      const { hasPreviousPage, hasNextPage } = this.violations.pageInfo || {};
      return hasPreviousPage || hasNextPage;
    },
  },
  methods: {
    handleSortChanged(sortState) {
      this.sortParam = sortObjectToString(sortState);
      this.updateUrlQuery({ ...this.urlQuery, sort: this.sortParam });
    },
    toggleDrawer(rows) {
      const { mergeRequest, project } = rows[0] || {};

      if (!mergeRequest || this.isCurrentDrawer(mergeRequest)) {
        this.closeDrawer();
      } else {
        this.openDrawer(mergeRequest, project);
      }
    },
    isCurrentDrawer(mergeRequest) {
      return this.showDrawer && mergeRequest.id === this.drawerMergeRequest.id;
    },
    openDrawer(mergeRequest, project) {
      this.showDrawer = true;
      this.drawerMergeRequest = mergeRequest;
      this.drawerProject = project;
    },
    closeDrawer() {
      this.showDrawer = false;
      // Refs are required by BTable to manipulate the selection
      // issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1531
      this.$refs.table.$children[0].clearSelected();
      this.drawerMergeRequest = {};
      this.drawerProject = {};
    },
    updateUrlQuery({ projectIds = [], ...rest }) {
      this.urlQuery = {
        // Clear the URL param when the id array is empty
        projectIds: projectIds?.length > 0 ? projectIds : null,
        ...rest,
      };
    },
    loadPrevPage(startCursor) {
      this.paginationCursors = {
        before: startCursor,
        after: null,
      };
    },
    loadNextPage(endCursor) {
      this.paginationCursors = {
        before: null,
        after: endCursor,
      };
    },
  },
  fields: [
    {
      key: 'severity',
      label: __('Severity'),
      thClass: thWidthClass(10),
      sortable: true,
    },
    {
      key: 'violationReason',
      label: __('Violation'),
      thClass: thWidthClass(15),
      sortable: true,
    },
    {
      key: 'mergeRequestTitle',
      label: __('Merge request'),
      thClass: thWidthClass(40),
      sortable: true,
    },
    {
      key: 'mergedAt',
      label: __('Date merged'),
      thClass: thWidthClass(20),
      sortable: true,
    },
    {
      key: 'viewDetails',
      label: '',
      thClass: 'gl-display-none',
      tdClass: 'gl-md-display-none view-details',
    },
  ],
  i18n: {
    heading: __('Compliance report'),
    subheading: __(
      'The compliance report shows the merge request violations merged in protected environments.',
    ),
    queryError: __('Retrieving the compliance report failed. Refresh the page and try again.'),
    noViolationsFound: s__('ComplianceReport|No violations found'),
    learnMore: __('Learn more.'),
    prev: __('Prev'),
    next: __('Next'),
    viewDetailsBtn: __('View details'),
  },
  documentationPath: helpPagePath('user/compliance/compliance_report/index.md', {
    anchor: 'approval-status-and-separation-of-duties',
  }),
  DRAWER_Z_INDEX,
};
</script>

<template>
  <section>
    <gl-alert v-if="queryError" variant="danger" class="gl-mt-3" :dismissible="false">
      {{ $options.i18n.queryError }}
    </gl-alert>
    <header
      class="gl-mt-5 gl-mb-6 gl-display-flex gl-sm-flex-direction-column gl-justify-content-space-between"
    >
      <div>
        <h2 class="gl-flex-grow-1 gl-my-0">{{ $options.i18n.heading }}</h2>
        <p class="gl-mt-5" data-testid="subheading">
          {{ $options.i18n.subheading }}
          <gl-link :href="$options.documentationPath" target="_blank">{{
            $options.i18n.learnMore
          }}</gl-link>
        </p>
      </div>
      <merge-commits-export-button
        v-if="hasMergeCommitsCsvExportPath"
        :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
      />
    </header>
    <violation-filter
      :group-path="groupPath"
      :default-query="defaultQuery"
      @filters-changed="updateUrlQuery"
    />
    <gl-table
      ref="table"
      :fields="$options.fields"
      :items="violations.list"
      :busy="isLoading"
      :empty-text="$options.i18n.noViolationsFound"
      :selectable="true"
      :sort-by="sortBy"
      :sort-desc="sortDesc"
      no-local-sorting
      sort-icon-left
      show-empty
      head-variant="white"
      stacked="lg"
      select-mode="single"
      hover
      selected-variant="primary"
      class="compliance-report-table"
      thead-class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
      @row-selected="toggleDrawer"
      @sort-changed="handleSortChanged"
    >
      <template #cell(severity)="{ item: { severity } }">
        <severity-badge class="gl-reset-text-align!" :severity="severity" />
      </template>
      <template #cell(violationReason)="{ item: { reason, violatingUser } }">
        <violation-reason :reason="reason" :user="violatingUser" />
      </template>
      <template #cell(mergeRequestTitle)="{ item: { mergeRequest } }">
        {{ mergeRequest.title }}
      </template>
      <template #cell(mergedAt)="{ item: { mergeRequest } }">
        <time-ago-tooltip :time="mergeRequest.mergedAt" />
      </template>
      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="gl-my-5" />
      </template>
      <template #cell(viewDetails)="{ item }">
        <gl-button class="gl-mb-0" block @click="toggleDrawer([item])">
          {{ $options.i18n.viewDetailsBtn }}
        </gl-button>
      </template>
    </gl-table>
    <div v-if="showPagination" class="gl-display-flex gl-justify-content-center">
      <gl-keyset-pagination
        v-bind="violations.pageInfo"
        :disabled="isLoading"
        :prev-text="$options.i18n.prev"
        :next-text="$options.i18n.next"
        @prev="loadPrevPage"
        @next="loadNextPage"
      />
    </div>
    <merge-request-drawer
      :show-drawer="showDrawer"
      :merge-request="drawerMergeRequest"
      :project="drawerProject"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDrawer"
    />
    <url-sync :query="urlQuery" />
  </section>
</template>
