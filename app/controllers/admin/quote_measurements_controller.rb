class Admin::QuoteMeasurementsController < Admin::BaseController
  layout "quote_workflow"

  before_action :set_quote

  def show
    @project = @quote.project
    @rooms = @project ? @project.rooms.ordered.includes(:windows, :photos) : []
    @quote_photos = @quote.photos.where(room_id: nil).ordered
  end

  def create_room
    ensure_project!

    @room = @quote.project.rooms.create!(room_params)
    redirect_to measurements_admin_quote_path(@quote), notice: "Room \"#{@room.name}\" added."
  end

  def create_photo
    @photo = Photo.new(photo_params)
    @photo.quote = @quote

    if @photo.save
      redirect_to measurements_admin_quote_path(@quote), notice: "Photo uploaded."
    else
      redirect_to measurements_admin_quote_path(@quote), alert: "Photo upload failed: #{@photo.errors.full_messages.to_sentence}"
    end
  end

  def destroy_photo
    @photo = @quote.photos.find(params[:photo_id])
    @photo.destroy!
    redirect_to measurements_admin_quote_path(@quote), notice: "Photo removed."
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def ensure_project!
    return if @quote.project

    project = Project.create!(
      client: @quote.client,
      user_id: current_user.id,
      title: "Measurements for #{@quote.client.display_name}",
      status: :discovery
    )
    @quote.update!(project: project)
  end

  def room_params
    params.require(:room).permit(:name, :notes, :position)
  end

  def photo_params
    params.require(:photo).permit(:label, :kind, :room_id, :window_id, :image)
  end
end
