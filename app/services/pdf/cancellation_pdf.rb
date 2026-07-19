module Pdf
  class CancellationPdf < Base
    private

    def draw_body(pdf)
      2.times { |i| draw_copy(pdf, i) }
    end

    def draw_copy(pdf, index)
      pdf.move_down 20

      pdf.text "NOTICE OF CANCELLATION", style: :bold, size: 16, align: :center, color: "776B63"
      pdf.move_down 16

      pdf.text "Date of Transaction: #{formatted_date(@quote.created_at)}", size: 10
      pdf.move_down 6
      pdf.text "Client Name: #{client_name}", size: 10
      pdf.move_down 6
      pdf.text "Project Location: #{project_location}", size: 10
      pdf.move_down 16

      pdf.text "YOU MAY CANCEL THIS TRANSACTION, WITHOUT ANY PENALTY OR OBLIGATION, WITHIN THREE (3) BUSINESS DAYS FROM THE ABOVE DATE.", style: :bold, size: 10
      pdf.move_down 8

      cancellation_text.each do |paragraph|
        pdf.text paragraph, size: 9
        pdf.move_down 6
      end

      pdf.move_down 8
      pdf.text "NOT LATER THAN MIDNIGHT OF #{formatted_date(cancellation_deadline)} (insert date, three business days after the date of transaction).", size: 9
      pdf.move_down 12
      pdf.text "I hereby cancel this transaction.", style: :bold, size: 10
      pdf.move_down 24
      pdf.text "Client Signature: ______________________________________              Date: ______________", size: 10

      if index == 0
        pdf.start_new_page
      end
    end

    def cancellation_text
      [
        "If you cancel, any property traded in, any payments made by you under the contract, and any negotiable instrument executed by you will be returned within ten (10) business days following receipt by Brooke & Maisy Interior Designs, LLC of your cancellation notice, and any security interest arising out of the transaction will be cancelled.",
        "If you cancel, you must make available to Brooke & Maisy Interior Designs, LLC, at your residence and in substantially as good condition as when received, any goods delivered to you under this contract; or you may, if you wish, comply with any instructions from Brooke & Maisy Interior Designs, LLC regarding the return shipment of the goods at its expense and risk.",
        "If you do make the goods available and Brooke & Maisy Interior Designs, LLC does not pick them up within 20 days of the date of this Notice of Cancellation, you may retain or dispose of the goods without further obligation. If you fail to make the goods available, or if you agree to return them and fail to do so, you remain liable for performance of all obligations under the contract.",
        "To cancel this transaction, sign and date this notice and mail, deliver, or email a copy to:",
        "Brooke & Maisy Interior Designs, LLC\nAttn: Amanda Nelson\n1726 Gold Hill Rd., #1071\nFort Mill, SC. 29708\namanda@brookenmaisy.com\n(980) 277-0709"
      ]
    end

    def cancellation_deadline
      date = @quote.created_at.to_date
      count = 0
      while count < 3
        date += 1.day
        count += 1 unless date.saturday? || date.sunday?
      end
      date
    end
  end
end
