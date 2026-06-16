class Admin::MessagesController < Admin::BaseController
  def index
    @messages = Message.recent
  end

  def show
    @message = Message.find(params[:id])
    @message.update(read: true) unless @message.read?
  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy
    redirect_to admin_messages_path, notice: "Message deleted."
  end
end
