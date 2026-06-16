class MessagesController < ApplicationController
  def create
    @message = Message.new(message_params)

    if @message.save
      redirect_to contact_path, notice: "Thank you! Your message has been sent."
    else
      redirect_to contact_path, alert: "Please fill in all required fields."
    end
  end

  private

  def message_params
    params.require(:message).permit(:name, :email, :phone, :service, :body)
  end
end
