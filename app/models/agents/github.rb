class Github < Agent
  def request_options
    { bearer: personal_access_token }
  end

  def get_query_url(options={})
    url % { owner: options[:owner], repo: options[:repo] }
  end

  def get_events_url(options={})
    events_url % { owner: options[:owner], repo: options[:repo] }
  end

  def get_total(options={})
    Work.tracked.where(registration_agency: 'github').count
  end

  def queue_jobs(options={})
    return 0 unless active?

    works = Work.tracked.where(registration_agency: 'github').pluck(:id)
    total = works.size

    works.each_slice(job_batch_size) do |ids|
      AgentJob.set(queue: queue, wait_until: schedule_at).perform_later(self, options.merge(ids: ids))
    end

    # return number of works queued
    total
  end

  def get_data(options={})
    work = Work.where(id: options[:work_id]).first
    return {} unless work.present? && github_repo(work.canonical_url).present?

    query_url = get_query_url(get_owner_and_repo(work))
    get_result(query_url, options.merge(request_options))
  end

  def get_owner_and_repo(work)
    # code from https://github.com/octokit/octokit.rb/blob/master/lib/octokit/repository.rb
    full_name = URI.parse(work.canonical_url).path[1..-1]
    owner, repo = full_name.split('/')
    { owner: owner, repo: repo }
  end

  def parse_data(result, options={})
    return result if result[:error]
    work = Work.where(id: options[:work_id]).first
    return { error: "Resource not found.", status: 404 } unless work.present?

    relations = []
    stargazers_count = result.fetch("stargazers_count", 0)
    if stargazers_count > 0
      relations << { relation: { "subj_id" => work.pid,
                                 "obj_id" => "https://github.com/",
                                 "relation_type_id" => "is_bookmarked_by",
                                 "total" => stargazers_count,
                                 "source_id" => source_id },
                     obj: { "pid" => "https://github.com/",
                            "URL" => "https://github.com/",
                            "title" => "Github",
                            "issued" => { "date-parts" => [[2008, 2, 8]] }} }
    end

    forks_count = result.fetch("forks_count", 0)
    if forks_count > 0
      relations << { relation: { "subj_id" => work.pid,
                                 "obj_id" => "https://github.com/",
                                 "relation_type_id" => "is_source_of",
                                 "total" => forks_count,
                                 "source_id" => source_id },
                     obj: { "pid" => "https://github.com/",
                            "URL" => "https://github.com/",
                            "title" => "Github",
                            "issued" => { "date-parts" => [[2008, 2, 8]] }} }
    end

    relations
  end

  def config_fields
    [:url, :events_url, :personal_access_token]
  end

  def url
    "https://api.github.com/repos/%{owner}/%{repo}"
  end

  def events_url
    "https://github.com/%{owner}/%{repo}"
  end

  # More info at https://github.com/blog/1509-personal-api-tokens
  def personal_access_token
    config.personal_access_token
  end

  def personal_access_token=(value)
    config.personal_access_token = value
  end

  def rate_limiting
    config.rate_limiting || 5000
  end

  def cron_line
    config.cron_line || "40 20 * * *"
  end
end
