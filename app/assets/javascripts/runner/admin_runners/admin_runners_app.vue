<script>
import { GlLink } from '@gitlab/ui';
import createFlash from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import { updateHistory } from '~/lib/utils/url_utility';
import { formatNumber, sprintf, __ } from '~/locale';

import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerPagination from '../components/runner_pagination.vue';

import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import { tagTokenConfig } from '../components/search_tokens/tag_token_config';
import { typeTokenConfig } from '../components/search_tokens/type_token_config';
import { ADMIN_FILTERED_SEARCH_NAMESPACE, INSTANCE_TYPE, I18N_FETCH_ERROR } from '../constants';
import getRunnersQuery from '../graphql/get_runners.query.graphql';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from '../runner_search_utils';
import { captureException } from '../sentry_utils';

export default {
  name: 'AdminRunnersApp',
  components: {
    GlLink,
    RegistrationDropdown,
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerName,
    RunnerPagination,
  },
  props: {
    activeRunnersCount: {
      type: Number,
      required: true,
    },
    registrationToken: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      search: fromUrlQueryToSearch(),
      runners: {
        items: [],
        pageInfo: {},
      },
    };
  },
  apollo: {
    runners: {
      query: getRunnersQuery,
      // Runners can be updated by users directly in this list.
      // A "cache and network" policy prevents outdated filtered
      // results.
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.variables;
      },
      update(data) {
        const { runners } = data;
        return {
          items: runners?.nodes || [],
          pageInfo: runners?.pageInfo || {},
        };
      },
      error(error) {
        createFlash({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
  },
  computed: {
    variables() {
      return fromSearchToVariables(this.search);
    },
    runnersLoading() {
      return this.$apollo.queries.runners.loading;
    },
    noRunnersFound() {
      return !this.runnersLoading && !this.runners.items.length;
    },
    activeRunnersMessage() {
      return sprintf(__('Runners currently online: %{active_runners_count}'), {
        active_runners_count: formatNumber(this.activeRunnersCount),
      });
    },
    searchTokens() {
      return [
        statusTokenConfig,
        typeTokenConfig,
        {
          ...tagTokenConfig,
          recentTokenValuesStorageKey: `${this.$options.filteredSearchNamespace}-recent-tags`,
        },
      ];
    },
  },
  watch: {
    search: {
      deep: true,
      handler() {
        // TODO Implement back button reponse using onpopstate
        updateHistory({
          url: fromSearchToUrl(this.search),
          title: document.title,
        });
      },
    },
  },
  errorCaptured(error) {
    this.reportToSentry(error);
  },
  methods: {
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  filteredSearchNamespace: ADMIN_FILTERED_SEARCH_NAMESPACE,
  INSTANCE_TYPE,
};
</script>
<template>
  <div>
    <div class="gl-py-3 gl-display-flex">
      <registration-dropdown
        class="gl-ml-auto"
        :registration-token="registrationToken"
        :type="$options.INSTANCE_TYPE"
        right
      />
    </div>

    <runner-filtered-search-bar
      v-model="search"
      :tokens="searchTokens"
      :namespace="$options.filteredSearchNamespace"
    >
      <template #runner-count>
        {{ activeRunnersMessage }}
      </template>
    </runner-filtered-search-bar>

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <template v-else>
      <runner-list :runners="runners.items" :loading="runnersLoading">
        <template #runner-name="{ runner }">
          <gl-link :href="runner.adminUrl">
            <runner-name :runner="runner" />
          </gl-link>
        </template>
      </runner-list>
      <runner-pagination v-model="search.pagination" :page-info="runners.pageInfo" />
    </template>
  </div>
</template>
