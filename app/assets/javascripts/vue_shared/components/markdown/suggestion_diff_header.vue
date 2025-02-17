<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import ApplySuggestion from './apply_suggestion.vue';

export default {
  components: { GlIcon, GlButton, GlLoadingIcon, ApplySuggestion },
  directives: { 'gl-tooltip': GlTooltipDirective },
  props: {
    batchSuggestionsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    canApply: {
      type: Boolean,
      required: false,
      default: false,
    },
    isApplied: {
      type: Boolean,
      required: true,
      default: false,
    },
    isBatched: {
      type: Boolean,
      required: false,
      default: false,
    },
    isApplyingBatch: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    defaultCommitMessage: {
      type: String,
      required: false,
      default: null,
    },
    inapplicableReason: {
      type: String,
      required: false,
      default: null,
    },
    suggestionsCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      isApplyingSingle: false,
    };
  },

  computed: {
    isApplying() {
      return this.isApplyingSingle || this.isApplyingBatch;
    },
    tooltipMessage() {
      if (!this.canApply) {
        return this.inapplicableReason;
      }

      return this.batchSuggestionsCount > 1
        ? __('This also resolves all related threads')
        : __('This also resolves this thread');
    },
    isDisableButton() {
      return this.isApplying || !this.canApply;
    },
    applyingSuggestionsMessage() {
      if (this.isApplyingSingle || this.batchSuggestionsCount < 2) {
        return __('Applying suggestion...');
      }

      return __('Applying suggestions...');
    },
    isLoggedIn() {
      return isLoggedIn();
    },
    showApplySuggestion() {
      if (!this.isLoggedIn) return false;

      if (this.batchSuggestionsCount >= 1 && !this.isBatched) {
        return false;
      }

      return true;
    },
  },
  methods: {
    apply(message) {
      if (this.batchSuggestionsCount > 1) {
        this.applySuggestionBatch(message);
      } else {
        this.applySuggestion(message);
      }
    },
    applySuggestion(message) {
      if (!this.canApply) return;
      this.isApplyingSingle = true;

      this.$emit('apply', this.applySuggestionCallback, message);
    },
    applySuggestionCallback() {
      this.isApplyingSingle = false;
    },
    applySuggestionBatch(message) {
      if (!this.canApply) return;
      this.$emit('applyBatch', message);
    },
    addSuggestionToBatch() {
      this.$emit('addToBatch');
    },
    removeSuggestionFromBatch() {
      this.$emit('removeFromBatch');
    },
  },
};
</script>

<template>
  <div class="md-suggestion-header border-bottom-0 mt-2">
    <div class="js-suggestion-diff-header font-weight-bold">
      {{ __('Suggested change') }}
      <a v-if="helpPagePath" :href="helpPagePath" :aria-label="__('Help')" class="js-help-btn">
        <gl-icon name="question-o" css-classes="link-highlight" />
      </a>
    </div>
    <div v-if="isApplied" class="badge badge-success" data-qa-selector="applied_badge">
      {{ __('Applied') }}
    </div>
    <div
      v-else-if="isApplying"
      class="d-flex align-items-center text-secondary"
      data-qa-selector="applying_badge"
    >
      <gl-loading-icon size="sm" class="d-flex-center mr-2" />
      <span>{{ applyingSuggestionsMessage }}</span>
    </div>
    <div v-else-if="isLoggedIn" class="d-flex align-items-center">
      <div v-if="isBatched">
        <gl-button
          class="btn-inverted js-remove-from-batch-btn btn-grouped"
          :disabled="isApplying"
          @click="removeSuggestionFromBatch"
        >
          {{ __('Remove from batch') }}
        </gl-button>
      </div>
      <div v-else-if="!isDisableButton && suggestionsCount > 1">
        <gl-button
          class="btn-inverted js-add-to-batch-btn btn-grouped"
          data-qa-selector="add_suggestion_batch_button"
          :disabled="isDisableButton"
          @click="addSuggestionToBatch"
        >
          {{ __('Add suggestion to batch') }}
        </gl-button>
      </div>
      <apply-suggestion
        v-if="showApplySuggestion"
        v-gl-tooltip.viewport="tooltipMessage"
        :disabled="isDisableButton"
        :default-commit-message="defaultCommitMessage"
        :batch-suggestions-count="batchSuggestionsCount"
        class="gl-ml-3"
        @apply="apply"
      />
    </div>
  </div>
</template>
