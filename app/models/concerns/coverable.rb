module Coverable
  extend ActiveSupport::Concern

  included do
    def get_query_url(work)
      return {} unless work.doi =~ /^10.1371/

      url_private % { :doi => work.doi_escaped }
    end

    def response_options
      { metrics: :comments }
    end

    def get_related_works(result, work)
      Array(result.fetch('referrals', nil)).map do |item|
        timestamp = get_iso8601_from_time(item.fetch('published_on', nil))
        type = item.fetch("type", nil)
        type = MEDIACURATION_TYPE_TRANSLATIONS.fetch(type, nil) if type

        {
          "author" => nil,
          "title" => item.fetch("title", ""),
          "container-title" => item.fetch("publication", ""),
          "issued" => get_date_parts(timestamp),
          "timestamp" => timestamp,
          "URL" => item.fetch('referral', nil),
          "type" => type,
          "related_works" => [{ "related_work" => work.pid,
                                "source" => name,
                                "relation_type" => "discusses" }] }
      end
    end

    def config_fields
      [:url_private]
    end
  end
end