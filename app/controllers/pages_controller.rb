class PagesController < ApplicationController
  def home
    @featured_projects = Project.complete.recent.limit(3).with_attached_photos
    @featured_trade_partners = TradePartner.active.ordered.limit(3)
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
    @trade_partners = TradePartner.active.ordered
    @trade_partners = @trade_partners.by_type(params[:type]) if params[:type].present?
  end
end
