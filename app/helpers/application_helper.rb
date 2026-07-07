module ApplicationHelper
  def safe_external_url(url)
    return nil if url.blank?
    return url if url.start_with?("http://", "https://")

    nil
  end
end
