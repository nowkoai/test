<script>
import { GlLink, GlIcon, GlButton, GlProgressBar } from '@gitlab/ui';

export default {
  name: 'StatisticsCard',
  components: { GlLink, GlIcon, GlButton, GlProgressBar },
  props: {
    usageValue: {
      type: String,
      required: false,
      default: null,
    },
    usageUnit: {
      type: String,
      required: false,
      default: null,
    },
    totalValue: {
      type: String,
      required: false,
      default: null,
    },
    totalUnit: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    helpLink: {
      type: String,
      required: false,
      default: null,
    },
    percentage: {
      type: Number,
      required: false,
      default: null,
    },
    purchaseButtonLink: {
      type: String,
      required: false,
      default: null,
    },
    purchaseButtonText: {
      type: String,
      required: false,
      default: null,
    },
    cssClass: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div
    class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-5 gl-rounded-base"
    data-testid="container"
    :class="cssClass"
  >
    <div class="gl-display-flex gl-justify-content-space-between gl-mb-3">
      <p
        v-if="usageValue"
        class="gl-font-size-h-display gl-font-weight-bold"
        data-testid="denominator"
      >
        {{ usageValue }}
        <span v-if="usageUnit" data-testid="denominator-usage-unit" class="gl-font-lg">{{
          usageUnit
        }}</span>
        <span v-if="totalValue" data-testid="denominator-total">
          /
          {{ totalValue }}
          <span v-if="totalUnit" class="gl-font-lg" data-testid="denominator-total-unit">{{
            totalUnit
          }}</span>
        </span>
      </p>

      <div>
        <gl-button
          v-if="purchaseButtonLink && purchaseButtonText"
          :href="purchaseButtonLink"
          category="primary"
          variant="confirm"
        >
          {{ purchaseButtonText }}
        </gl-button>
      </div>
    </div>
    <p v-if="description" class="gl-font-weight-bold gl-mt-3" data-testid="description">
      {{ description }}
      <gl-link
        v-if="helpLink"
        :href="helpLink"
        target="_blank"
        rel="noopener noreferrer nofollow"
        class="gl-ml-2"
      >
        <gl-icon name="question-o" />
      </gl-link>
    </p>
    <gl-progress-bar v-if="percentage" :value="percentage" />
  </div>
</template>
