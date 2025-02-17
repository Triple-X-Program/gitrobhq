<script>
import { GlAlert, GlLoadingIcon, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getParameterValues, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import {
  CREATE_TAB,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_ERROR,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
  LINT_TAB,
  MERGED_TAB,
  TAB_QUERY_PARAM,
  TABS_INDEX,
  VISUALIZE_TAB,
} from '../constants';
import getAppStatus from '../graphql/queries/client/app_status.graphql';
import CiConfigMergedPreview from './editor/ci_config_merged_preview.vue';
import CiEditorHeader from './editor/ci_editor_header.vue';
import TextEditor from './editor/text_editor.vue';
import CiLint from './lint/ci_lint.vue';
import EditorTab from './ui/editor_tab.vue';

export default {
  i18n: {
    tabEdit: s__('Pipelines|Edit'),
    tabGraph: s__('Pipelines|Visualize'),
    tabLint: s__('Pipelines|Lint'),
    tabMergedYaml: s__('Pipelines|View merged YAML'),
    empty: {
      visualization: s__(
        'PipelineEditor|The pipeline visualization is displayed when the CI/CD configuration file has valid syntax.',
      ),
      lint: s__(
        'PipelineEditor|The CI/CD configuration is continuously validated. Errors and warnings are displayed when the CI/CD configuration file is not empty.',
      ),
      merge: s__(
        'PipelineEditor|The merged YAML view is displayed when the CI/CD configuration file has valid syntax.',
      ),
    },
  },
  errorTexts: {
    loadMergedYaml: s__('Pipelines|Could not load merged YAML content'),
  },
  query: {
    TAB_QUERY_PARAM,
  },
  tabConstants: {
    CREATE_TAB,
    LINT_TAB,
    MERGED_TAB,
    VISUALIZE_TAB,
  },
  components: {
    CiConfigMergedPreview,
    CiEditorHeader,
    CiLint,
    EditorTab,
    GlAlert,
    GlLoadingIcon,
    GlTabs,
    PipelineGraph,
    TextEditor,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    ciFileContent: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    appStatus: {
      query: getAppStatus,
    },
  },
  computed: {
    hasAppError() {
      // Not an invalid config and with `mergedYaml` data missing
      return this.appStatus === EDITOR_APP_STATUS_ERROR;
    },
    isEmpty() {
      return this.appStatus === EDITOR_APP_STATUS_EMPTY;
    },
    isInvalid() {
      return this.appStatus === EDITOR_APP_STATUS_INVALID;
    },
    isValid() {
      return this.appStatus === EDITOR_APP_STATUS_VALID;
    },
    isLoading() {
      return this.appStatus === EDITOR_APP_STATUS_LOADING;
    },
  },
  created() {
    const [tabQueryParam] = getParameterValues(TAB_QUERY_PARAM);

    if (tabQueryParam && TABS_INDEX[tabQueryParam]) {
      this.setDefaultTab(tabQueryParam);
    }
  },
  methods: {
    setCurrentTab(tabName) {
      this.$emit('set-current-tab', tabName);
    },
    setDefaultTab(tabName) {
      // We associate tab name with the index so that we can use tab name
      // in other part of the app and load the corresponding tab closer to the
      // actual component using a hash that binds the name to the indexes.
      // This also means that if we ever changed tab order, we would justs need to
      // update `TABS_INDEX` hash instead of all the instances in the app
      // where we used the individual indexes
      const newUrl = setUrlParams({ [TAB_QUERY_PARAM]: TABS_INDEX[tabName] });

      this.setCurrentTab(tabName);
      updateHistory({ url: newUrl, title: document.title, replace: true });
    },
  },
};
</script>
<template>
  <gl-tabs
    class="file-editor gl-mb-3"
    :query-param-name="$options.query.TAB_QUERY_PARAM"
    sync-active-tab-with-query-params
  >
    <editor-tab
      class="gl-mb-3"
      :title="$options.i18n.tabEdit"
      lazy
      data-testid="editor-tab"
      @click="setCurrentTab($options.tabConstants.CREATE_TAB)"
    >
      <ci-editor-header />
      <text-editor :commit-sha="commitSha" :value="ciFileContent" v-on="$listeners" />
    </editor-tab>
    <editor-tab
      class="gl-mb-3"
      :empty-message="$options.i18n.empty.visualization"
      :is-empty="isEmpty"
      :is-invalid="isInvalid"
      :keep-component-mounted="false"
      :title="$options.i18n.tabGraph"
      lazy
      data-testid="visualization-tab"
      @click="setCurrentTab($options.tabConstants.VISUALIZE_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <pipeline-graph v-else :pipeline-data="ciConfigData" />
    </editor-tab>
    <editor-tab
      class="gl-mb-3"
      :empty-message="$options.i18n.empty.lint"
      :is-empty="isEmpty"
      :title="$options.i18n.tabLint"
      data-testid="lint-tab"
      @click="setCurrentTab($options.tabConstants.LINT_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <ci-lint v-else :is-valid="isValid" :ci-config="ciConfigData" />
    </editor-tab>
    <editor-tab
      class="gl-mb-3"
      :empty-message="$options.i18n.empty.merge"
      :keep-component-mounted="false"
      :is-empty="isEmpty"
      :is-invalid="isInvalid"
      :title="$options.i18n.tabMergedYaml"
      lazy
      data-testid="merged-tab"
      @click="setCurrentTab($options.tabConstants.MERGED_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <gl-alert v-else-if="hasAppError" variant="danger" :dismissible="false">
        {{ $options.errorTexts.loadMergedYaml }}
      </gl-alert>
      <ci-config-merged-preview v-else :ci-config-data="ciConfigData" v-on="$listeners" />
    </editor-tab>
  </gl-tabs>
</template>
