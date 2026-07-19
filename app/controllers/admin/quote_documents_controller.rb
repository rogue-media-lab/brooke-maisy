require "stringio"

class Admin::QuoteDocumentsController < Admin::BaseController
  layout "quote_workflow"

  before_action :set_quote

  FORMS = {
    agreement: { label: "Design & Installation Services Agreement", class: "Pdf::AgreementPdf" },
    cancellation: { label: "Notice of Cancellation (2 copies)", class: "Pdf::CancellationPdf" },
    work_order_client: { label: "Work Order - Client", class: "Pdf::WorkOrderClientPdf" },
    work_order_internal: { label: "Work Order - Internal", class: "Pdf::WorkOrderInternalPdf" },
    invoice: { label: "Invoice", class: "Pdf::InvoicePdf" }
  }.freeze

  def show
    @quote.bump_workflow_stage!(:contract)
    @signatures = @quote.signatures.ordered
  end

  def sign
    @signature = Signature.new
  end

  def create_signature
    @signature = @quote.signatures.build(signature_params)
    @signature.signer = :client
    @signature.document_type = :agreement
    @signature.signed_at = Time.current
    @signature.signature_ip = request.remote_ip

    if @signature.signature_data.present?
      # Decode base64 PNG and attach to ActiveStorage
      data = @signature.signature_data.sub(/^data:image\/png;base64,/, "")
      decoded = Base64.decode64(data)
      @signature.signature_image.attach(
        io: StringIO.new(decoded),
        filename: "signature_#{@quote.id}_client.png",
        content_type: "image/png"
      )
    end

    if @signature.save
      # Lock the quote after client signs
      @quote.update!(status: :ordered) if @quote.draft?

      redirect_to admin_documents_path(@quote),
                  notice: "Client signature captured. Quote has been locked."
    else
      render :sign, status: :unprocessable_entity
    end
  end

  def download
    form_key = params[:form].to_sym
    form = FORMS[form_key]

    unless form
      redirect_to admin_documents_path(@quote), alert: "Unknown form type."
      return
    end

    generator = form[:class].constantize.new(@quote)
    pdf_data = generator.render

    send_data pdf_data,
              filename: "#{form_key}_quote_#{@quote.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  rescue StandardError => e
    redirect_to admin_documents_path(@quote), alert: "Failed to generate PDF: #{e.message}"
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id] || params[:id])
  end

  def signature_params
    params.require(:signature).permit(:signed_name, :signature_data)
  end
end
