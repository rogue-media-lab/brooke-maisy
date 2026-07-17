class Admin::QuotesController < Admin::BaseController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_quote, only: [ :show, :edit, :update, :destroy, :send_quote, :preview, :save_as_template ]

  def index
    @quotes = @project.quotes.live.includes(:client).recent
  end

  def templates
    @templates = Quote.templates.includes(:project, :client).recent
  end

  def load
    template = Quote.templates.find(params[:template_id])
    project = Project.find(params[:project_id])

    new_quote = project.quotes.create!(
      client: template.client,
      notes: template.notes,
      tax_rate: template.tax_rate,
      deposit_percentage: template.deposit_percentage,
      valid_until: 30.days.from_now.to_date,
      is_template: false,
      version_number: 1
    )

    template.quote_line_items.ordered.each do |item|
      new_quote.quote_line_items.create!(
        product: item.product,
        window: item.window,
        swatch: item.swatch,
        description: item.description,
        quantity: item.quantity,
        unit_cost: item.unit_cost,
        unit_price: item.unit_price,
        width: item.width,
        height: item.height,
        selected_options: item.selected_options,
        notes: item.notes,
        comparison_group: item.comparison_group,
        position: item.position,
        status: :proposed
      )
    end

    redirect_to admin_project_quote_path(project, new_quote), notice: "Quote created from template."
  end

  def show
    @calculator = QuoteCalculator.new(@quote).calculate
  end

  def new
    @quote = @project.quotes.new
    @clients = User.where(role: :client).order(:name)
  end

  def create
    @quote = @project.quotes.new(quote_params)
    @quote.version_number = 1
    if @quote.save
      redirect_to admin_project_quote_path(@project, @quote), notice: "Quote created."
    else
      @clients = User.where(role: :client).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = User.where(role: :client).order(:name)
  end

  def update
    if @quote.update(quote_params)
      redirect_to admin_project_quote_path(@quote.project, @quote), notice: "Quote updated."
    else
      @clients = User.where(role: :client).order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project = @quote.project
    @quote.destroy
    redirect_to admin_project_quotes_path(project), notice: "Quote removed."
  end

  def send_quote
    @quote.update!(status: :sent, sent_at: Time.current)
    QuoteMailer.send_quote(@quote).deliver_later
    redirect_to admin_project_quote_path(@quote.project, @quote), notice: "Quote sent to #{@quote.client.display_name}."
  end

  def preview
    @calculator = QuoteCalculator.new(@quote).calculate
    render layout: "admin"  # client preview in admin layout for now
  end

  def save_as_template
    @quote.update!(is_template: true)
    redirect_to admin_project_quotes_path(@quote.project), notice: "Quote saved as template."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_quote
    @quote = Quote.includes(quote_line_items: [ :product, :window, :swatch ]).find(params[:id])
  end

  def quote_params
    params.require(:quote).permit(
      :client_id, :promo_code_id, :status, :notes,
      :quote_discount_type, :quote_discount_value, :quote_discount_reason,
      :tax_rate, :deposit_percentage, :valid_until
    )
  end
end
