<script>
import { GlModal, GlModalDirective, GlFormTextarea, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
    GlFormTextarea,
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      userInput: null,
      modalId: uniqueId('delete-project-modal-'),
    };
  },
  computed: {
    confirmDisabled() {
      return this.userInput !== this.confirmPhrase;
    },
    csrfToken() {
      return csrf.token;
    },
    modalActionProps() {
      return {
        primary: {
          text: __('Yes, delete project'),
          attributes: [{ variant: 'danger' }, { disabled: this.confirmDisabled }],
        },
        cancel: {
          text: __('Cancel, keep project'),
        },
      };
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.submit();
    },
  },
  strings: {
    deleteProject: __('Delete project'),
    title: __('Delete project. Are you ABSOLUTELY SURE?'),
    confirmText: __('Please type the following to confirm:'),
  },
};
</script>

<template>
  <form ref="form" :action="formPath" method="post">
    <input type="hidden" name="_method" value="delete" />
    <input :value="csrfToken" type="hidden" name="authenticity_token" />

    <gl-button v-gl-modal="modalId" category="primary" variant="danger">{{
      $options.strings.deleteProject
    }}</gl-button>

    <gl-modal
      ref="removeModal"
      :modal-id="modalId"
      size="sm"
      ok-variant="danger"
      footer-class="gl-bg-gray-10 gl-p-5"
      title-class="gl-text-red-500"
      :action-primary="modalActionProps.primary"
      :action-cancel="modalActionProps.cancel"
      @ok="submitForm"
    >
      <template #modal-title>{{ $options.strings.title }}</template>
      <div>
        <slot name="modal-body"></slot>
        <p class="gl-mb-1">{{ $options.strings.confirmText }}</p>
        <p>
          <code class="gl-white-space-pre-wrap">{{ confirmPhrase }}</code>
        </p>
        <gl-form-textarea id="confirm_name_input" v-model="userInput" name="confirm_name_input" />
        <slot name="modal-footer"></slot>
      </div>
    </gl-modal>
  </form>
</template>
