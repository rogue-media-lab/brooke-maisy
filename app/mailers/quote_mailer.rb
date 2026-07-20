class QuoteMailer < ApplicationMailer
  default from: %("Brooke & Maisy" <amanda@brookenmaisy.com>)

  def send_quote(quote)
    @quote = quote
    @client = quote.client
    @calculator = QuoteCalculator.new(quote).calculate
    @project = quote.project

    mail(
      to: @client.email,
      subject: "Your Quote for #{@project.title}"
    )
  end
end
