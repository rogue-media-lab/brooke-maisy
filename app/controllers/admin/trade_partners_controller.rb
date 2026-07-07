class Admin::TradePartnersController < Admin::BaseController
  before_action :set_trade_partner, only: [ :show, :edit, :update, :destroy ]

  def index
    @trade_partners = TradePartner.ordered
    @type_counts = TradePartner.active.group(:trade_type).count
  end

  def show
  end

  def new
    @trade_partner = TradePartner.new
  end

  def create
    @trade_partner = TradePartner.new(trade_partner_params)
    if @trade_partner.save
      redirect_to admin_trade_partner_path(@trade_partner), notice: "Trade partner added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trade_partner.update(trade_partner_params)
      redirect_to admin_trade_partner_path(@trade_partner), notice: "Trade partner updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trade_partner.destroy
    redirect_to admin_trade_partners_path, notice: "Trade partner removed."
  end

  private

  def set_trade_partner
    @trade_partner = TradePartner.find(params[:id])
  end

  def trade_partner_params
    params.require(:trade_partner).permit(
      :name, :trade_type, :phone, :email, :website,
      :description, :years_experience, :rating, :jobs_referred,
      :active, :display_order
    )
  end
end
