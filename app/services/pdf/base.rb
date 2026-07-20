module Pdf
  class Base
    BUSINESS = {
      name: "Brooke & Maisy Interior Designs, LLC",
      address: "1726 Gold Hill Rd., #1071, Fort Mill, SC 29708",
      email: "amanda@brookeandmaisy.com",
      phone: "(980) 277-0709",
      owner: "Amanda Nelson, Owner"
    }.freeze

    def initialize(quote, signatures: [])
      @quote = quote
      @client = quote.client
      @calculator = QuoteCalculator.new(quote).calculate
      @signatures = signatures
    end

    def render
      pdf = Prawn::Document.new(document_options)
      setup_fonts(pdf)
      draw_header(pdf)
      draw_body(pdf)
      draw_footer(pdf)
      pdf.render
    end

    private

    def document_options
      { page_size: "LETTER", margin: [ 54, 54, 54, 54 ] }  # 0.75 inch in points
    end

    def setup_fonts(pdf)
      pdf.font_families.update(
        "Inter" => {
          normal: "/usr/share/fonts/truetype/inter/Inter-Regular.ttf",
          bold: "/usr/share/fonts/truetype/inter/Inter-Bold.ttf"
        }
      )
      pdf.font "Helvetica"
    rescue StandardError
      # Fall back to Helvetica if Inter not available
      pdf.font "Helvetica"
    end

    def draw_header(pdf)
      pdf.bounding_box([ 0, pdf.bounds.height + 36 ], width: pdf.bounds.width, height: 36) do
        pdf.font_size(10) do
          pdf.text BUSINESS[:name], style: :bold, size: 14, color: "776B63"
          pdf.text "#{BUSINESS[:address]} · #{BUSINESS[:phone]}", size: 8, color: "999999"
        end
      end
      pdf.stroke_horizontal_rule
    end

    def draw_body(pdf)
      raise NotImplementedError, "Subclasses must implement #draw_body"
    end

    def draw_footer(pdf)
      pdf.repeat(:all) do
        pdf.bounding_box([ 0, 36 ], width: pdf.bounds.width, height: 28) do
          pdf.stroke_horizontal_rule
          pdf.font_size(7) do
            pdf.text BUSINESS[:name], color: "999999"
            pdf.text "#{BUSINESS[:email]} · #{BUSINESS[:phone]}", color: "999999"
          end
        end
      end
    end

    def project_location
      @client&.address || @quote.project&.address || ""
    end

    def client_name
      @client&.display_name || ""
    end

    def formatted_date(date = Time.current)
      date.respond_to?(:strftime) ? date.strftime("%B %-d, %Y") : ""
    end

    def currency(amount)
      return "$0.00" unless amount
      "$#{format('%.2f', amount)}"
    end
  end
end
