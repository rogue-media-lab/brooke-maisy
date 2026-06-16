class PagesController < ApplicationController
  def home
    @featured_projects = Project.complete.recent.limit(3).with_attached_photos
  end

  def about
  end

  def services
  end

  def portfolio
    @projects = Project.complete.recent.with_attached_photos
  end

  def contact
  end

  def trade_network
  end
end
