class Projects::VariablesController < Projects::ApplicationController
  before_action :variable, only: [:show, :update, :destroy]
  before_action :authorize_admin_build!

  layout 'project_settings'

  def index
    redirect_to project_settings_ci_cd_path(@project)
  end

  def show
  end

  def update
    if variable.update(variable_params)
      redirect_to project_variables_path(project),
                  notice: 'Variable was successfully updated.'
    else
      render "show"
    end
  end

  def create
    @variable = project.variables.create(variable_params)
      .present(current_user: current_user)

    if @variable.persisted?
      redirect_to project_settings_ci_cd_path(project),
                  notice: 'Variable was successfully created.'
    else
      render "show"
    end
  end

  def save_multiple
    respond_to do |format|
      format.json do
        variables = variables_from_params(variables_params)
        return head :bad_request unless variables.all?(&:valid?)

        variables.each(&:save)
        head :ok
      end
    end
  end

  def destroy
    if variable.destroy
      redirect_to project_settings_ci_cd_path(project),
                  status: 302,
                  notice: 'Variable was successfully removed.'
    else
      redirect_to project_settings_ci_cd_path(project),
                  status: 302,
                  notice: 'Failed to remove the variable.'
    end
  end

  private

  def variable_params
    params.require(:variable).permit(*variable_params_attributes)
  end

  def variables_params
    params.permit(variables: [*variable_params_attributes])
  end

  def variables_from_params(params)
    params[:variables].map do |variable_hash|
      variable = project.variables.where(key: variable_hash[:key])
        .first_or_initialize(variable_hash)
      variable.assign_attributes(variable_hash) unless variable.new_record?
      variable
    end
  end

  def variable_params_attributes
    %i[id key value protected _destroy]
  end

  def variable
    @variable ||= project.variables.find(params[:id]).present(current_user: current_user)
  end
end
