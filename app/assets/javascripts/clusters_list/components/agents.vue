<script>
import { GlAlert, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { MAX_LIST_COUNT, ACTIVE_CONNECTION_TIME } from '../constants';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import AgentEmptyState from './agent_empty_state.vue';
import AgentTable from './agent_table.vue';
import InstallAgentModal from './install_agent_modal.vue';

export default {
  apollo: {
    agents: {
      query: getAgentsQuery,
      variables() {
        return {
          defaultBranchName: this.defaultBranchName,
          projectPath: this.projectPath,
          ...this.cursor,
        };
      },
      update(data) {
        this.updateTreeList(data);
        return data;
      },
    },
  },
  components: {
    AgentEmptyState,
    AgentTable,
    InstallAgentModal,
    GlAlert,
    GlKeysetPagination,
    GlLoadingIcon,
  },
  inject: ['projectPath'],
  props: {
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
  },
  data() {
    return {
      cursor: {
        first: MAX_LIST_COUNT,
        last: null,
      },
      folderList: {},
    };
  },
  computed: {
    agentList() {
      let list = this.agents?.project?.clusterAgents?.nodes;

      if (list) {
        list = list.map((agent) => {
          const configFolder = this.folderList[agent.name];
          const lastContact = this.getLastContact(agent);
          const status = this.getStatus(lastContact);
          return { ...agent, configFolder, lastContact, status };
        });
      }

      return list;
    },
    agentPageInfo() {
      return this.agents?.project?.clusterAgents?.pageInfo || {};
    },
    isLoading() {
      return this.$apollo.queries.agents.loading;
    },
    showPagination() {
      return this.agentPageInfo.hasPreviousPage || this.agentPageInfo.hasNextPage;
    },
    treePageInfo() {
      return this.agents?.project?.repository?.tree?.trees?.pageInfo || {};
    },
    hasConfigurations() {
      return Boolean(this.agents?.project?.repository?.tree?.trees?.nodes?.length);
    },
  },
  methods: {
    reloadAgents() {
      this.$apollo.queries.agents.refetch();
    },
    nextPage() {
      this.cursor = {
        first: MAX_LIST_COUNT,
        last: null,
        afterAgent: this.agentPageInfo.endCursor,
        afterTree: this.treePageInfo.endCursor,
      };
    },
    prevPage() {
      this.cursor = {
        first: null,
        last: MAX_LIST_COUNT,
        beforeAgent: this.agentPageInfo.startCursor,
        beforeTree: this.treePageInfo.endCursor,
      };
    },
    updateTreeList(data) {
      const configFolders = data?.project?.repository?.tree?.trees?.nodes;

      if (configFolders) {
        configFolders.forEach((folder) => {
          this.folderList[folder.name] = folder;
        });
      }
    },
    getLastContact(agent) {
      const tokens = agent?.tokens?.nodes;
      let lastContact = null;
      if (tokens?.length) {
        tokens.forEach((token) => {
          const lastContactToDate = new Date(token.lastUsedAt).getTime();
          if (lastContactToDate > lastContact) {
            lastContact = lastContactToDate;
          }
        });
      }
      return lastContact;
    },
    getStatus(lastContact) {
      if (lastContact) {
        const now = new Date().getTime();
        const diff = now - lastContact;

        return diff > ACTIVE_CONNECTION_TIME ? 'inactive' : 'active';
      }
      return 'unused';
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-3" />

  <section v-else-if="agentList" class="gl-mt-3">
    <div v-if="agentList.length">
      <AgentTable :agents="agentList" />

      <div v-if="showPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-keyset-pagination v-bind="agentPageInfo" @prev="prevPage" @next="nextPage" />
      </div>
    </div>

    <AgentEmptyState v-else :has-configurations="hasConfigurations" />
    <InstallAgentModal @agentRegistered="reloadAgents" />
  </section>

  <gl-alert v-else variant="danger" :dismissible="false">
    {{ s__('ClusterAgents|An error occurred while loading your GitLab Agents') }}
  </gl-alert>
</template>
