# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches group settings', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'in general settings page' do
    let(:visit_path) { edit_group_path(group) }

    it_behaves_like 'can search settings with feature flag check', 'Naming', 'Permissions'
  end

  context 'in Repository page' do
    before do
      visit group_settings_repository_path(group)
    end

    it_behaves_like 'can search settings', 'Deploy tokens', 'Default initial branch name'
  end

  context 'in CI/CD page' do
    before do
      visit group_settings_ci_cd_path(group)
    end

    it_behaves_like 'can search settings', 'Variables', 'Runners'
  end
end
