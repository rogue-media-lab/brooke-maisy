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
      redirect_to admin_client_path(@client),
                  notice: "#{@client.display_name} invited. A set-password email has been sent."
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
