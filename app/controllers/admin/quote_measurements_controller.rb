class Admin::QuoteMeasurementsController < Admin::BaseController
  layout "quote_workflow"

  before_action :set_quote

  def show
    @quote.bump_workflow_stage!(:measurements)
    @project = @quote.project
    @rooms = @project ? @project.rooms.ordered.includes(:windows, :photos) : []
    @quote_photos = @quote.photos.where(room_id: nil).ordered
  end

  def create_room
    ensure_project!

    @room = @quote.project.rooms.create!(room_params)
    redirect_to measurements_admin_quote_path(@quote), notice: "Room \"#{@room.name}\" added."
  end

  def create_window
    ensure_project!
    room = @quote.project.rooms.find(params[:window][:room_id])
    @window = room.windows.new(window_params)

    if @window.save
      redirect_to measurements_admin_quote_path(@quote), notice: "Window \"#{@window.name}\" added to #{room.name}."
    else
      redirect_to measurements_admin_quote_path(@quote), alert: "Window creation failed: #{@window.errors.full_messages.to_sentence}"
    end
  end

  def destroy_window
    room = @quote.project.rooms.find(params[:room_id])
    window = room.windows.find(params[:window_id])
    window.destroy!
    redirect_to measurements_admin_quote_path(@quote), notice: "Window removed."
  end

  def update_window
    room = @quote.project.rooms.find(params[:room_id])
    window = room.windows.find(params[:window_id])
    if window.update(window_params)
      redirect_to measurements_admin_quote_path(@quote), notice: "Window \"#{window.name}\" updated."
    else
      redirect_to measurements_admin_quote_path(@quote), alert: "Update failed: #{window.errors.full_messages.to_sentence}"
    end
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

  def window_params
    params.require(:window).permit(:name, :width, :height, :mount_type, :depth, :notes, :photo)
  end

  def photo_params
    params.require(:photo).permit(:label, :kind, :room_id, :window_id, :image)
  end
end
