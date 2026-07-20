require "stringio"

class Admin::QuoteDocumentsController < Admin::BaseController
  layout "quote_workflow"

  before_action :set_quote

  # Forms the client signs — shown in the workflow with signing flow
  WORKFLOW_FORMS = {
    agreement: { label: "Design & Installation Services Agreement", class: "Pdf::AgreementPdf", doc_type: :agreement, needs_designer: true },
    cancellation: { label: "Notice of Cancellation", class: "Pdf::CancellationPdf", doc_type: :cancellation, needs_designer: false }
  }.freeze

  def show
    @quote.bump_workflow_stage!(:contract)
    @signatures = @quote.signatures.ordered
  end

  def sign
    @signature = Signature.new
    @doc_type = params[:doc] || "agreement"
  end

  def sign_designer
    @signature = Signature.new
    @designer_mode = true
    @doc_type = params[:doc] || "agreement"
    render :sign
  end

  def create_signature
    @signature = @quote.signatures.build(signature_params)
    signer_val = params[:signer] || "client"
    doc_type_val = params[:document_type] || "agreement"
    @signature.signer = signer_val
    @signature.document_type = doc_type_val
    @signature.signed_at = Time.current
    @signature.signature_ip = request.remote_ip

    if @signature.signature_data.present?
      data = @signature.signature_data.sub(/^data:image\/png;base64,/, "")
      decoded = Base64.decode64(data)
      @signature.signature_image.attach(
        io: StringIO.new(decoded),
        filename: "signature_#{@quote.id}_#{@signature.signer}.png",
        content_type: "image/png"
      )
    end

    if @signature.save
      # Lock the quote only after client signs
      if @signature.signer == "client" && @quote.draft?
        @quote.update!(status: :ordered)
      end

      # Send email notification
      SignatureMailer.signed(@quote, @signature).deliver_later if @client&.email.present? rescue nil

      redirect_to admin_documents_path(@quote),
                  notice: "#{@signature.signer.humanize} signature captured." +
                          (@signature.signer == "client" ? " Quote has been locked." : "")
    else
      @designer_mode = (signer_val == "designer")
      @doc_type = doc_type_val
      render :sign, status: :unprocessable_entity
    end
  end

  def download
    form_key = params[:form].to_sym
    form = WORKFLOW_FORMS[form_key]

    unless form
      redirect_to admin_documents_path(@quote), alert: "Unknown form type."
      return
    end

    generator = form[:class].constantize.new(@quote, signatures: @quote.signatures.to_a)
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
