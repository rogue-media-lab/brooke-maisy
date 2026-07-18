class Admin::ClientsController < Admin::BaseController
  before_action :set_client, only: [ :show, :edit, :update, :destroy, :invite, :resend_invite ]

  def index
    @clients = Client.alphabetical
  end

  def show
    @projects = @client.projects.recent
    @quotes = @client.quotes.live.recent
  end

  def new
    @client = Client.new

    if params[:quick]
      render :quick, layout: "admin_minimal"
    end
  end

  def selector
    @clients = Client.alphabetical
    @selected_id = params[:selected_id]
  end

  # Creates a Client record. The portal invite flow is a separate action
  # (`invite`) — creating a client here does NOT generate credentials or
  # send any email.
  def create
    @client = Client.new(client_params)

    if @client.save
      if params[:return_to].present?
        separator = params[:return_to].include?("?") ? "&" : "?"
        redirect_to "#{params[:return_to]}#{separator}new_client_id=#{@client.id}",
                    notice: "#{@client.display_name} added and selected."
      else
        redirect_to admin_client_path(@client), notice: "#{@client.display_name} added."
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

  # Invite a client to the portal. If they already have a user account,
  # resend the reset-password instructions. Otherwise create a User linked
  # to this client and send the set-password email.
  def invite
    if @client.email.blank?
      redirect_to admin_client_path(@client), alert: "An email is required for portal access."
      return
    end

    if @client.user
      @client.user.send_reset_password_instructions
      redirect_to admin_client_path(@client), notice: "Invitation email re-sent."
    else
      user = @client.build_user(
        name: @client.name,
        email: @client.email,
        role: "client",
        password: SecureRandom.base58(24)
      )

      if user.save
        user.send_reset_password_instructions
        redirect_to admin_client_path(@client), notice: "#{@client.display_name} invited. A set-password email has been sent."
      else
        redirect_to admin_client_path(@client), alert: "Could not create portal access: #{user.errors.full_messages.to_sentence}."
      end
    end
  end

  alias_method :resend_invite, :invite

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :address, :notes)
  end
end
