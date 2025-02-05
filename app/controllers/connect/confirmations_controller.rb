class Connect::ConfirmationsController < Devise::ConfirmationsController

  # def after_confirmation_path_for(resource_name, resource)
  # end

  # NOTE : we hook the confirmation token area
  # so we can trigger a reward for it if a challenge was started beforehand
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      # if the user triggered this challenge and succesfully confirmed his email
      # we trigger reward end `fill_in_email`
      # he should receive an email with his reward.
      if reward_manager.started?
        reward_manager.end
      end

      flash[:success] = I18n.t('devise.confirmations.confirmed')
    else
      flash[:error] = "#{resource.errors.full_messages.join(', ')}"
    end
    # NOTE : we redirect to a special blank page
    # we will solely show a message witout layout
    # whatever happens
    redirect_to guest_blank_path

  end

  private

    def reward_manager
      @reward_manager ||= RewardManager.new(resource, task: :fill_in_email)
    end
end
