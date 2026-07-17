class Admin::ClientsController < Admin::BaseController
  before_action :set_client, only: [ :show, :edit, :update, :destroy, :resend_invite ]

  def index
    @clients = User.where(role: "client").order(:name)
  end

  def show
    @projects = @client.projects.recent
  end

  def new
    @client = User.new(role: "client")

    if params[:quick]
      render :quick, layout: "admin_minimal"
    end
  end

  def selector
    @clients = User.where(role: "client").order(:name)
    @selected_id = params[:selected_id]
  end

  # Creates a client with a random password and sends a "set your password"
  # email (Devise recoverable). This is the invite-only onboarding flow —
  # the client never self-registers.
  def create
    @client = User.new(client_params)
    @client.role = "client"
    @client.password = SecureRandom.base58(24)

    if @client.save
      @client.send_reset_password_instructions

      if params[:return_to].present?
        separator = params[:return_to].include?("?") ? "&" : "?"
        redirect_to "#{params[:return_to]}#{separator}new_client_id=#{@client.id}",
                    notice: "#{@client.display_name} added and selected."
      else
        redirect_to admin_client_path(@client),
                    notice: "#{@client.display_name} invited. A set-password email has been sent."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to admin_client_path(@client), notice: "Client updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path, notice: "Client removed."
  end

  def resend_invite
    @client.send_reset_password_instructions
    redirect_to admin_client_path(@client), notice: "Invitation email re-sent."
  end

  private

  def set_client
    @client = User.where(role: "client").find(params[:id])
  end

  def client_params
    params.require(:user).permit(:name, :email)
  end
end
