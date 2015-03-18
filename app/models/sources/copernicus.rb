# encoding: UTF-8

class Copernicus < Source
  def get_query_url(work)
    return nil unless work.doi =~ /^10.5194/

    url_private % { :doi => work.doi }
  end

  def request_options
    { username: username, password: password }
  end

  def parse_data(result, work, options={})
    return result if result[:error]

    events = result.fetch('counter') { {} }

    pdf = events.fetch('PdfDownloads') { 0 }
    html = events.fetch('AbstractViews') { 0 }
    total = events.values.reduce(0) { |sum, x| x.nil? ? sum : sum + x }

    events = result['data'] ? {} : result

    { events: events,
      events_by_day: [],
      events_by_month: [],
      events_url: nil,
      event_count: total,
      event_metrics: get_event_metrics(pdf: pdf, html: html, total: total) }
  end

  def config_fields
    [:url_private, :username, :password]
  end
end
