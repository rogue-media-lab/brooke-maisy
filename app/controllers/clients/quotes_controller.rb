class Clients::QuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote

  def show
    authorize @quote, policy_class: Clients::QuotePolicy
    @calculator = QuoteCalculator.new(@quote).calculate
    @project = @quote.project

    # Mark as viewed if this is first client view
    @quote.update!(status: :viewed) if @quote.sent?
  end

  def approve
    authorize @quote, policy_class: Clients::QuotePolicy

    snapshot = build_snapshot
    @quote.update!(status: :approved, approved_at: Time.current)
    @quote.quote_revisions.create!(reason: "Client approved", snapshot: snapshot)

    redirect_to clients_quote_path(@quote),
                notice: "Quote approved! We'll begin processing your order."
  end

  def approve_line_item
    authorize @quote, policy_class: Clients::QuotePolicy

    item = @quote.quote_line_items.find(params[:id])
    item.update!(status: :approved)

    redirect_to clients_quote_path(@quote),
                notice: "#{item.product&.name || 'Item'} approved."
  end

  def decline_line_item
    authorize @quote, policy_class: Clients::QuotePolicy

    item = @quote.quote_line_items.find(params[:id])
    item.update!(status: :declined)

    redirect_to clients_quote_path(@quote),
                notice: "#{item.product&.name || 'Item'} declined. We'll follow up."
  end

  private

  def set_quote
    @quote = Quote.includes(quote_line_items: [ :product, :window, :swatch ])
                  .find(params[:quote_id] || params[:id])
  end

  def build_snapshot
    {
      subtotal: @quote.subtotal,
      grand_total: @quote.grand_total,
      line_items: @quote.quote_line_items.ordered.map do |li|
        {
          product: li.product&.name,
          quantity: li.quantity,
          unit_price: li.unit_price,
          line_total: li.line_total,
          status: li.status
        }
      end
    }
  end
end
