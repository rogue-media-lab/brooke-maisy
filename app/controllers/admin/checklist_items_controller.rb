class Admin::ChecklistItemsController < Admin::BaseController
  before_action :set_checklist_item, only: [ :edit, :update, :destroy ]

  def index
    @checklist_items = ChecklistItem.ordered
  end

  def new
    @checklist_item = ChecklistItem.new
  end

  def create
    @checklist_item = ChecklistItem.new(checklist_item_params)
    if @checklist_item.save
      redirect_to admin_checklist_items_path, notice: "Checklist item added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @checklist_item.update(checklist_item_params)
      redirect_to admin_checklist_items_path, notice: "Checklist item updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @checklist_item.destroy
    redirect_to admin_checklist_items_path, notice: "Checklist item removed."
  end

  private

  def set_checklist_item
    @checklist_item = ChecklistItem.find(params[:id])
  end

  def checklist_item_params
    params.require(:checklist_item).permit(:name, :position, :active)
  end
end