class Admin::QuoteDocumentsController < Admin::BaseController
  layout "quote_workflow"

  before_action :set_quote

  FORMS = {
    agreement: { label: "Design & Installation Services Agreement", class: "Pdf::AgreementPdf" },
    cancellation: { label: "Notice of Cancellation (2 copies)", class: "Pdf::CancellationPdf" },
    work_order_client: { label: "Work Order — Client", class: "Pdf::WorkOrderClientPdf" },
    work_order_internal: { label: "Work Order — Internal", class: "Pdf::WorkOrderInternalPdf" },
    invoice: { label: "Invoice", class: "Pdf::InvoicePdf" }
  }.freeze

  def show
    @signatures = @quote.signatures.ordered
  end

  def download
    form_key = params[:form].to_sym
    form = FORMS[form_key]

    unless form
      redirect_to admin_quote_documents_path(@quote), alert: "Unknown form type."
      return
    end

    generator = form[:class].constantize.new(@quote)
    pdf_data = generator.render

    send_data pdf_data,
              filename: "#{form_key}_quote_#{@quote.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  rescue StandardError => e
    redirect_to admin_quote_documents_path(@quote), alert: "Failed to generate PDF: #{e.message}"
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id] || params[:id])
  end
end
