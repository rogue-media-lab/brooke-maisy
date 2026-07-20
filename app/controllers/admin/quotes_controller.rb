class Admin::QuotesController < Admin::BaseController
  before_action :set_quote, only: [ :show, :edit, :update, :destroy, :send_quote, :preview, :save_as_template, :convert_to_project ]

  def index
    @quotes = Quote.live.includes(:client, :project, quote_line_items: :product)
    @quotes = @quotes.by_project(params[:project_id]) if params[:project_id].present?
    @quotes = @quotes.by_client(params[:client_id]) if params[:client_id].present?

    case params[:sort]
    when "client"
      @quotes = @quotes.joins(:client).order("clients.name ASC")
    when "oldest"
      @quotes = @quotes.order(created_at: :asc)
    when "total"
      @quotes = @quotes.recent
    when "status"
      @quotes = @quotes.order(:status, created_at: :desc)
    else
      @quotes = @quotes.recent
    end

    @quotes = @quotes.to_a
    # Pre-compute totals for each quote
    @quote_totals = {}
    @quotes.each do |q|
      @quote_totals[q.id] = QuoteCalculator.new(q).calculate
    end
  end

  def templates
    @templates = Quote.templates.includes(:client, :project).recent
  end

  def load
    template = Quote.templates.find(params[:template_id])
    project_id = params[:project_id].presence

    new_quote = Quote.new(
      client: template.client,
      project_id: project_id,
      notes: template.notes,
      tax_rate: template.tax_rate,
      deposit_percentage: template.deposit_percentage,
      valid_until: 30.days.from_now.to_date,
      is_template: false,
      version_number: 1
    )

    template.quote_line_items.ordered.each do |item|
      new_quote.quote_line_items.build(
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

    new_quote.save!

    redirect_to admin_quote_path(new_quote), notice: "Quote created from template."
  end

  def show
    @quote.bump_workflow_stage!(:product_choices) if @quote.quote_line_items.any?
    @calculator = QuoteCalculator.new(@quote).calculate
    render layout: "quote_workflow"
  end

  def new
    @quote = Quote.new(
      client_id: params[:client_id],
      project_id: params[:project_id],
      tax_rate: 0.06,
      valid_until: 30.days.from_now.to_date
    )
    @clients = Client.alphabetical
    @projects = @quote.client_id.present? ? @quote.client.projects.recent : []
  end

  def create
    @quote = Quote.new(quote_params)
    @quote.version_number = 1
    @quote.status = :draft
    if @quote.save
      redirect_to admin_quote_path(@quote), notice: "Quote created."
    else
      @clients = Client.alphabetical
      @projects = @quote.client_id.present? ? @quote.client.projects.recent : []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = Client.alphabetical
    @projects = @quote.client_id.present? ? @quote.client.projects.recent : []
    render layout: "quote_workflow"
  end

  def update
    if @quote.update(quote_params)
      redirect_to admin_quote_path(@quote), notice: "Quote updated."
    else
      @clients = Client.alphabetical
      @projects = @quote.client_id.present? ? @quote.client.projects.recent : []
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.destroy
    redirect_to admin_quotes_path, notice: "Quote removed."
  end

  def send_quote
    @quote.update!(status: :sent, sent_at: Time.current)
    QuoteMailer.send_quote(@quote).deliver_later
    redirect_to admin_quote_path(@quote), notice: "Quote sent to #{@quote.client.display_name}."
  end

  def preview
    @quote.bump_workflow_stage!(:quote_review)
    @calculator = QuoteCalculator.new(@quote).calculate
    render layout: "quote_workflow"
  end

  def save_as_template
    @quote.update!(is_template: true)
    redirect_to admin_quote_path(@quote), notice: "Quote saved as template."
  end

  def convert_to_project
    if @quote.project.present?
      redirect_to admin_quote_path(@quote), notice: "Quote already linked to a project."
      return
    end
    project = Project.create!(
      client: @quote.client,
      title: "Project for #{@quote.client.display_name}",
      status: :discovery
    )
    @quote.update!(project: project)
    redirect_to admin_project_path(project), notice: "Project created from quote."
  end

  private

  def set_quote
    @quote = Quote.includes(quote_line_items: [ :product, :window, :swatch ]).find(params[:id])
  end

  def quote_params
    params.require(:quote).permit(
      :client_id, :project_id, :promo_code_id, :status, :notes,
      :quote_discount_type, :quote_discount_value, :quote_discount_reason,
      :tax_rate, :deposit_percentage, :valid_until
    )
  end
end
