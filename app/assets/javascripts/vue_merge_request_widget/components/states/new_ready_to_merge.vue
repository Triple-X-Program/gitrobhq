<script>
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import readyToMergeQuery from '../../queries/states/new_ready_to_merge.query.graphql';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  apollo: {
    canMerge: {
      query: readyToMergeQuery,
      skip() {
        return !this.mr || !window.gon?.features?.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data?.project?.mergeRequest?.userPermissions?.canMerge,
    },
  },
  components: {
    StatusIcon,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      canMerge: null,
    };
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon status="success" />
    <p class="media-body gl-m-0! gl-font-weight-bold">
      <template v-if="canMerge">
        {{ __('Ready to merge!') }}
      </template>
      <template v-else>
        {{ __('Ready to merge by members who can write to the target branch.') }}
      </template>
    </p>
  </div>
</template>
