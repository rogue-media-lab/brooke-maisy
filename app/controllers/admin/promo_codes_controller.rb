class Admin::PromoCodesController < Admin::BaseController
  before_action :set_promo_code, only: [ :show, :edit, :update, :destroy ]

  def index
    @promo_codes = PromoCode.order(created_at: :desc)
  end

  def show; end

  def new
    @promo_code = PromoCode.new
  end

  def create
    @promo_code = PromoCode.new(promo_code_params)
    if @promo_code.save
      redirect_to admin_promo_codes_path, notice: "Promo code created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @promo_code.update(promo_code_params)
      redirect_to admin_promo_codes_path, notice: "Promo code updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @promo_code.destroy
    redirect_to admin_promo_codes_path, notice: "Promo code removed."
  end

  private

  def set_promo_code
    @promo_code = PromoCode.find(params[:id])
  end

  def promo_code_params
    params.require(:promo_code).permit(:code, :discount_type, :discount_value, :min_purchase, :expires_at, :usage_limit, :is_active)
  end
end
