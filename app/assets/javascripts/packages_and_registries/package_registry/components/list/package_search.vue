<script>
import { s__ } from '~/locale';
import { sortableFields } from '~/packages/list/utils';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { getQueryParams, extractFilterAndSorting } from '~/packages_and_registries/shared/utils';
import {
  FILTERED_SEARCH_TERM,
  FILTERED_SEARCH_TYPE,
} from '~/packages_and_registries/shared/constants';
import PackageTypeToken from './tokens/package_type_token.vue';

export default {
  tokens: [
    {
      type: 'type',
      icon: 'package',
      title: s__('PackageRegistry|Type'),
      unique: true,
      token: PackageTypeToken,
      operators: OPERATOR_IS_ONLY,
    },
  ],
  components: { RegistrySearch, UrlSync },
  inject: ['isGroupPage'],
  data() {
    return {
      filters: [],
      sorting: {
        orderBy: 'name',
        sort: 'desc',
      },
      mountRegistrySearch: false,
    };
  },
  computed: {
    sortableFields() {
      return sortableFields(this.isGroupPage);
    },
    parsedSorting() {
      const cleanOrderBy = this.sorting?.orderBy.replace('_at', '');
      return `${cleanOrderBy}_${this.sorting?.sort}`.toUpperCase();
    },
    parsedFilters() {
      const parsed = {
        packageName: '',
        packageType: undefined,
      };

      return this.filters.reduce((acc, filter) => {
        if (filter.type === FILTERED_SEARCH_TYPE && filter.value?.data) {
          return {
            ...acc,
            packageType: filter.value.data.toUpperCase(),
          };
        }

        if (filter.type === FILTERED_SEARCH_TERM) {
          return {
            ...acc,
            packageName: `${acc.packageName} ${filter.value.data}`.trim(),
          };
        }

        return acc;
      }, parsed);
    },
  },
  mounted() {
    const queryParams = getQueryParams(window.document.location.search);
    const { sorting, filters } = extractFilterAndSorting(queryParams);
    this.updateSorting(sorting);
    this.updateFilters(filters);
    this.mountRegistrySearch = true;
    this.emitUpdate();
  },
  methods: {
    updateFilters(newValue) {
      this.filters = newValue;
    },
    updateSorting(newValue) {
      this.sorting = { ...this.sorting, ...newValue };
    },
    updateSortingAndEmitUpdate(newValue) {
      this.updateSorting(newValue);
      this.emitUpdate();
    },
    emitUpdate() {
      this.$emit('update', { sort: this.parsedSorting, filters: this.parsedFilters });
    },
  },
};
</script>

<template>
  <url-sync>
    <template #default="{ updateQuery }">
      <registry-search
        v-if="mountRegistrySearch"
        :filter="filters"
        :sorting="sorting"
        :tokens="$options.tokens"
        :sortable-fields="sortableFields"
        @sorting:changed="updateSortingAndEmitUpdate"
        @filter:changed="updateFilters"
        @filter:submit="emitUpdate"
        @query:changed="updateQuery"
      />
    </template>
  </url-sync>
</template>
