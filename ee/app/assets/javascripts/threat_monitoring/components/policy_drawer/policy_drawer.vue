<script>
import { GlButton, GlDrawer, GlTabs, GlTab } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight, removeUnnecessaryDashes } from '../../utils';
import { POLICIES_LIST_CONTAINER_CLASS, POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import CiliumNetworkPolicy from './cilium_network_policy.vue';
import ScanExecutionPolicy from './scan_execution_policy.vue';
import ScanResultPolicy from './scan_result_policy.vue';

const policyComponent = {
  [POLICY_TYPE_COMPONENT_OPTIONS.container.value]: CiliumNetworkPolicy,
  [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value]: ScanExecutionPolicy,
  [POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value]: ScanResultPolicy,
};

export default {
  components: {
    GlButton,
    GlDrawer,
    GlTab,
    GlTabs,
    PolicyYamlEditor: () =>
      import(/* webpackChunkName: 'policy_yaml_editor' */ '../policy_yaml_editor.vue'),
    CiliumNetworkPolicy,
    ScanExecutionPolicy,
    ScanResultPolicy,
  },
  props: {
    containerClass: {
      type: String,
      required: false,
      default: POLICIES_LIST_CONTAINER_CLASS,
    },
    policy: {
      type: Object,
      required: false,
      default: null,
    },
    policyType: {
      type: String,
      required: false,
      default: '',
    },
    editPolicyPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    policyComponent() {
      return policyComponent[this.policyType] || null;
    },
    policyYaml() {
      return removeUnnecessaryDashes(this.policy.yaml);
    },
  },
  methods: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight(this.containerClass);
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :z-index="$options.DRAWER_Z_INDEX"
    :header-height="getDrawerHeaderHeight()"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template v-if="policy" #title>
      <h4 class="gl-my-0 gl-mr-3">{{ policy.name }}</h4>
    </template>
    <template v-if="policy" #header>
      <gl-button
        class="gl-mt-5"
        data-testid="edit-button"
        category="primary"
        variant="info"
        :href="editPolicyPath"
        >{{ s__('NetworkPolicies|Edit policy') }}</gl-button
      >
    </template>
    <gl-tabs v-if="policy" class="gl-p-0!" justified content-class="gl-py-0" lazy>
      <gl-tab title="Details" class="gl-mt-5 gl-ml-6 gl-mr-3">
        <component :is="policyComponent" v-if="policyComponent" :policy="policy" />
        <div v-else>
          <h5>{{ s__('NetworkPolicies|Policy definition') }}</h5>
          <p>
            {{ s__("NetworkPolicies|Define this policy's location, conditions and actions.") }}
          </p>
          <policy-yaml-editor
            :value="policyYaml"
            data-testid="policy-yaml-editor-default-component"
          />
        </div>
      </gl-tab>
      <gl-tab v-if="policyComponent" title="Yaml">
        <policy-yaml-editor
          class="gl-h-100vh"
          :value="policyYaml"
          data-testid="policy-yaml-editor-tab-content"
        />
      </gl-tab>
    </gl-tabs>
  </gl-drawer>
</template>
