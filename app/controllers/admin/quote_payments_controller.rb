class Admin::QuotePaymentsController < Admin::BaseController
  layout "quote_workflow"

  before_action :set_quote

  def show
    @quote.bump_workflow_stage!(:payment)
    @calculator = QuoteCalculator.new(@quote).calculate
    @payments = @quote.payments.ordered
    @total_paid = @payments.sum(&:amount)
    @balance_due = (@calculator[:grand_total] - @total_paid).round(2)
    @payment = Payment.new(paid_at: Date.current)
  end

  def create
    @payment = @quote.payments.build(payment_params)

    if @payment.save
      redirect_to payment_admin_quote_path(@quote), notice: "Payment of $#{@payment.amount} recorded."
    else
      @calculator = QuoteCalculator.new(@quote).calculate
      @payments = @quote.payments.ordered
      @total_paid = @payments.sum(&:amount)
      @balance_due = (@calculator[:grand_total] - @total_paid).round(2)
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @payment = @quote.payments.find(params[:payment_id])
    @payment.destroy!
    redirect_to payment_admin_quote_path(@quote), notice: "Payment removed."
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :method, :kind, :paid_at, :reference, :notes)
  end
end
