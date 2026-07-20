class Admin::PurchaseOrdersController < Admin::BaseController
  before_action :set_purchase_order, only: [ :show, :edit, :update, :destroy, :submit, :confirm_delivery, :mark_shipped, :mark_received ]

  def index
    @purchase_orders = PurchaseOrder.includes(:manufacturer, :quote, :client).recent
  end

  def show
    @line_items = @purchase_order.purchase_order_line_items.includes(:quote_line_item, :product)
  end

  def new
    @purchase_order = PurchaseOrder.new(manufacturer_id: params[:manufacturer_id], quote_id: params[:quote_id])
    @manufacturers = Manufacturer.order(:name)
    @clients = Client.alphabetical
    @quotes = Quote.where(status: [ :approved, :ordered ]).includes(:project).recent
    # Pre-load approved line items from the selected quote
    if params[:quote_id].present?
      @quote = Quote.find(params[:quote_id])
      @approved_items = @quote.quote_line_items.ordered.includes(:product)
      @purchase_order.client_id = @quote.client_id
      @purchase_order.project_id = @quote.project_id
    end
  end

  def create
    @purchase_order = PurchaseOrder.new(po_params)
    @purchase_order.status = :draft
    @purchase_order.order_date = Date.current

    # If quote_id present, inherit client and project from quote
    if @purchase_order.quote_id.present? && @purchase_order.client_id.nil?
      quote = Quote.find_by(id: @purchase_order.quote_id)
      @purchase_order.client_id = quote&.client_id
      @purchase_order.project_id = quote&.project_id
    end

    if @purchase_order.save
      # If quote_id is present, auto-add approved line items from that manufacturer
      if params[:quote_id].present?
        quote = Quote.find(params[:quote_id])
        items = quote.quote_line_items.ordered
                     .where(status: :approved)
                     .joins(:product)
                     .where(products: { manufacturer_id: @purchase_order.manufacturer_id })

        items.each do |item|
          @purchase_order.purchase_order_line_items.create!(
            quote_line_item: item,
            product: item.product,
            quantity: item.quantity,
            unit_cost: item.unit_cost || 0,
            total_cost: (item.unit_cost || 0) * (item.quantity || 1),
            status: :pending
          )
        end
      end

      redirect_to admin_purchase_order_path(@purchase_order), notice: "Purchase order created."
    else
      @manufacturers = Manufacturer.order(:name)
      @quotes = Quote.where(status: [ :approved, :ordered ]).includes(:project).recent
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @manufacturers = Manufacturer.order(:name)
    @clients = Client.alphabetical
    @quotes = Quote.where(status: [ :approved, :ordered ]).includes(:project).recent
  end

  def update
    if @purchase_order.update(po_params)
      redirect_to admin_purchase_order_path(@purchase_order), notice: "Purchase order updated."
    else
      @manufacturers = Manufacturer.order(:name)
      @clients = Client.alphabetical
      @quotes = Quote.where(status: [ :approved, :ordered ]).includes(:project).recent
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase_order.destroy
    redirect_to admin_purchase_orders_path, notice: "Purchase order removed."
  end

  def submit
    @purchase_order.update!(status: :submitted)
    redirect_to admin_purchase_order_path(@purchase_order), notice: "PO submitted to #{@purchase_order.manufacturer.name}."
  end

  def confirm_delivery
    @purchase_order.update!(status: :confirmed)
    redirect_to admin_purchase_order_path(@purchase_order), notice: "PO confirmed by #{@purchase_order.manufacturer.name}."
  end

  def mark_shipped
    @purchase_order.update!(status: :shipped)
    redirect_to admin_purchase_order_path(@purchase_order), notice: "PO marked as shipped."
  end

  def mark_received
    @purchase_order.update!(status: :received, actual_delivery: Date.current)
    redirect_to admin_purchase_order_path(@purchase_order), notice: "PO marked as received."
  end

  private

  def set_purchase_order
    @purchase_order = PurchaseOrder.includes(purchase_order_line_items: [ :quote_line_item, :product ])
                                   .find(params[:id])
  end

  def po_params
    params.require(:purchase_order).permit(
      :client_id, :project_id, :manufacturer_id, :quote_id, :status,
      :order_date, :expected_delivery, :actual_delivery, :notes
    )
  end
end
