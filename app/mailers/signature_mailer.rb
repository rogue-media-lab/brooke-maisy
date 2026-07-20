class SignatureMailer < ApplicationMailer
  def signed(quote, signature)
    @quote = quote
    @signature = signature
    @client = quote.client

    subject = if signature.signer == "client"
      "Agreement signed by #{@client&.display_name} - Quote ##{quote.id}"
    else
      "Designer signature added - Quote ##{quote.id}"
    end

    mail(to: [ "amanda@brookeandmaisy.com", @client&.email ].compact, subject: subject)
  end
end
