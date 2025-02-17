<script>
import { GlModal, GlAlert } from '@gitlab/ui';
import { mapGetters, mapActions, mapState } from 'vuex';
import { TYPE_USER, TYPE_ITERATION, TYPE_MILESTONE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { getParameterByName, visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { fullLabelId, fullBoardId } from '../boards_util';
import { formType } from '../constants';

import createBoardMutation from '../graphql/board_create.mutation.graphql';
import destroyBoardMutation from '../graphql/board_destroy.mutation.graphql';
import updateBoardMutation from '../graphql/board_update.mutation.graphql';
import BoardConfigurationOptions from './board_configuration_options.vue';

const boardDefaults = {
  id: false,
  name: '',
  labels: [],
  milestone: {},
  iteration_id: undefined,
  assignee: {},
  weight: null,
  hide_backlog_list: false,
  hide_closed_list: false,
};

export default {
  i18n: {
    [formType.new]: { title: s__('Board|Create new board'), btnText: s__('Board|Create board') },
    [formType.delete]: { title: s__('Board|Delete board'), btnText: __('Delete') },
    [formType.edit]: { title: s__('Board|Edit board'), btnText: __('Save changes') },
    scopeModalTitle: s__('Board|Board scope'),
    cancelButtonText: __('Cancel'),
    deleteErrorMessage: s__('Board|Failed to delete board. Please try again.'),
    saveErrorMessage: __('Unable to save your changes. Please try again.'),
    deleteConfirmationMessage: s__('Board|Are you sure you want to delete this board?'),
    titleFieldLabel: __('Title'),
    titleFieldPlaceholder: s__('Board|Enter board name'),
  },
  components: {
    BoardScope: () => import('ee_component/boards/components/board_scope.vue'),
    GlModal,
    BoardConfigurationOptions,
    GlAlert,
  },
  inject: {
    fullPath: {
      default: '',
    },
    rootPath: {
      default: '',
    },
  },
  props: {
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    scopedIssueBoardFeatureEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    weights: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentBoard: {
      type: Object,
      required: true,
    },
    currentPage: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      board: { ...boardDefaults, ...this.currentBoard },
      isLoading: false,
    };
  },
  computed: {
    ...mapState(['error']),
    ...mapGetters(['isIssueBoard', 'isGroupBoard', 'isProjectBoard']),
    isNewForm() {
      return this.currentPage === formType.new;
    },
    isDeleteForm() {
      return this.currentPage === formType.delete;
    },
    isEditForm() {
      return this.currentPage === formType.edit;
    },
    buttonText() {
      return this.$options.i18n[this.currentPage].btnText;
    },
    buttonKind() {
      if (this.isNewForm) {
        return 'success';
      }
      if (this.isDeleteForm) {
        return 'danger';
      }
      return 'confirm';
    },
    title() {
      if (this.readonly) {
        return this.$options.i18n.scopeModalTitle;
      }

      return this.$options.i18n[this.currentPage].title;
    },
    readonly() {
      return !this.canAdminBoard;
    },
    submitDisabled() {
      return this.isLoading || this.board.name.length === 0;
    },
    primaryProps() {
      return {
        text: this.buttonText,
        attributes: [
          {
            variant: this.buttonKind,
            disabled: this.submitDisabled,
            loading: this.isLoading,
            'data-qa-selector': 'save_changes_button',
          },
        ],
      };
    },
    cancelProps() {
      return {
        text: this.$options.i18n.cancelButtonText,
      };
    },
    currentMutation() {
      return this.board.id ? updateBoardMutation : createBoardMutation;
    },
    deleteMutation() {
      return destroyBoardMutation;
    },
    baseMutationVariables() {
      const { board } = this;
      const variables = {
        name: board.name,
        hideBacklogList: board.hide_backlog_list,
        hideClosedList: board.hide_closed_list,
      };

      return board.id
        ? {
            ...variables,
            id: fullBoardId(board.id),
          }
        : {
            ...variables,
            projectPath: this.isProjectBoard ? this.fullPath : undefined,
            groupPath: this.isGroupBoard ? this.fullPath : undefined,
          };
    },
    issueBoardScopeMutationVariables() {
      return {
        weight: this.board.weight,
        assigneeId: this.board.assignee?.id
          ? convertToGraphQLId(TYPE_USER, this.board.assignee.id)
          : null,
        milestoneId: this.board.milestone?.id
          ? convertToGraphQLId(TYPE_MILESTONE, this.board.milestone.id)
          : null,
        iterationId: this.board.iteration_id
          ? convertToGraphQLId(TYPE_ITERATION, this.board.iteration_id)
          : null,
      };
    },
    boardScopeMutationVariables() {
      return {
        labelIds: this.board.labels.map(fullLabelId),
        ...(this.isIssueBoard && this.issueBoardScopeMutationVariables),
      };
    },
    mutationVariables() {
      return {
        ...this.baseMutationVariables,
        ...(this.scopedIssueBoardFeatureEnabled ? this.boardScopeMutationVariables : {}),
      };
    },
  },
  mounted() {
    this.resetFormState();
    if (this.$refs.name) {
      this.$refs.name.focus();
    }
  },
  methods: {
    ...mapActions(['setError', 'unsetError']),
    boardCreateResponse(data) {
      return data.createBoard.board.webPath;
    },
    boardUpdateResponse(data) {
      const path = data.updateBoard.board.webPath;
      const param = getParameterByName('group_by')
        ? `?group_by=${getParameterByName('group_by')}`
        : '';
      return `${path}${param}`;
    },
    cancel() {
      this.$emit('cancel');
    },
    async createOrUpdateBoard() {
      const response = await this.$apollo.mutate({
        mutation: this.currentMutation,
        variables: { input: this.mutationVariables },
      });

      if (!this.board.id) {
        return this.boardCreateResponse(response.data);
      }

      return this.boardUpdateResponse(response.data);
    },
    async deleteBoard() {
      await this.$apollo.mutate({
        mutation: this.deleteMutation,
        variables: {
          id: fullBoardId(this.board.id),
        },
      });
    },
    async submit() {
      if (this.board.name.length === 0) return;
      this.isLoading = true;
      if (this.isDeleteForm) {
        try {
          await this.deleteBoard();
          visitUrl(this.rootPath);
        } catch {
          this.setError({ message: this.$options.i18n.deleteErrorMessage });
        } finally {
          this.isLoading = false;
        }
      } else {
        try {
          const url = await this.createOrUpdateBoard();
          visitUrl(url);
        } catch {
          this.setError({ message: this.$options.i18n.saveErrorMessage });
        } finally {
          this.isLoading = false;
        }
      }
    },
    resetFormState() {
      if (this.isNewForm) {
        // Clear the form when we open the "New board" modal
        this.board = { ...boardDefaults };
      } else if (this.currentBoard && Object.keys(this.currentBoard).length) {
        this.board = { ...boardDefaults, ...this.currentBoard };
      }
    },
    setIteration(iterationId) {
      this.board.iteration_id = iterationId;
    },
    setBoardLabels(labels) {
      this.board.labels = labels;
    },
    setAssignee(assigneeId) {
      this.$set(this.board, 'assignee', {
        id: assigneeId,
      });
    },
    setMilestone(milestoneId) {
      this.$set(this.board, 'milestone', {
        id: milestoneId,
      });
    },
    setWeight(weight) {
      this.$set(this.board, 'weight', weight);
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="board-config-modal"
    modal-class="board-config-modal"
    content-class="gl-absolute gl-top-7"
    visible
    :hide-footer="readonly"
    :title="title"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="submit"
    @cancel="cancel"
    @close="cancel"
    @hide.prevent
  >
    <gl-alert
      v-if="error"
      class="gl-mb-3"
      variant="danger"
      :dismissible="true"
      @dismiss="unsetError"
    >
      {{ error }}
    </gl-alert>
    <p v-if="isDeleteForm" data-testid="delete-confirmation-message">
      {{ $options.i18n.deleteConfirmationMessage }}
    </p>
    <form v-else class="js-board-config-modal" data-testid="board-form-wrapper" @submit.prevent>
      <div v-if="!readonly" class="gl-mb-5" data-testid="board-form">
        <label class="gl-font-weight-bold gl-font-lg" for="board-new-name">
          {{ $options.i18n.titleFieldLabel }}
        </label>
        <input
          id="board-new-name"
          ref="name"
          v-model="board.name"
          class="form-control"
          data-qa-selector="board_name_field"
          type="text"
          :placeholder="$options.i18n.titleFieldPlaceholder"
          @keyup.enter="submit"
        />
      </div>

      <board-configuration-options
        :hide-backlog-list.sync="board.hide_backlog_list"
        :hide-closed-list.sync="board.hide_closed_list"
        :readonly="readonly"
      />

      <board-scope
        v-if="scopedIssueBoardFeatureEnabled"
        :collapse-scope="isNewForm"
        :board="board"
        :can-admin-board="canAdminBoard"
        :weights="weights"
        @set-iteration="setIteration"
        @set-board-labels="setBoardLabels"
        @set-assignee="setAssignee"
        @set-milestone="setMilestone"
        @set-weight="setWeight"
      />
    </form>
  </gl-modal>
</template>
