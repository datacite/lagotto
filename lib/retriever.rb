
class Retriever
  attr_accessor :lazy, :only_source, :verbose, :raise_on_error

  def initialize(options={})
    @lazy = options[:lazy]
    @verbose = options[:verbose]
    @only_source = options[:only_source]
    @raise_on_error = options[:raise_on_error]
  end

  def update(article)
    if lazy and article.published_on and Date.today <= article.published_on
      puts "Skipping: not published yet" if verbose
      return
    end

    sources = Source.active
    if only_source
      sources = sources.select {|s| s.name.downcase == only_source.downcase }
      if sources.empty?
        puts("Source '#{only_source}' not found or not active") if verbose
        return
      end
    elsif sources.empty?
      puts("No active sources to update from") if verbose
      return
    end

    failed = false
    sources.each do |source|
      puts "Considering #{source.inspect}" if verbose
      retrieval = Retrieval.find_or_create_by_article_id_and_source_id(article.id, source.id)
      puts "Retrieval is#{" (new)" if retrieval.new_record?} #{retrieval.inspect} (lazy=#{lazy.inspect}, stale?=#{retrieval.stale?.inspect})" if verbose
      if (not lazy) or retrieval.stale?
        failed ||= update_one(retrieval, source, article)
      end
    end
    unless (only_source or failed)
      puts "Refreshing article #{article.inspect}" if verbose
      article.refreshed!.save!
    else
      puts "NOT refreshing article #{article.inspect}: failed=#{failed.inspect}" if verbose
    end
  end

  def update_one(retrieval, source, article)
    puts "Asking #{source.name} about #{article.doi}; last updated #{retrieval.retrieved_at}" if verbose
    failed = false
    begin
      raw_citations = source.query(article, :verbose => verbose)
      if raw_citations.is_a? Numeric
        puts "  Got a count of #{raw_citations.inspect} citations." if verbose
        retrieval.other_citations_count = raw_citations
        retrieval.retrieved_at = DateTime.now.utc
      else
        # Uniquify them - Sources sometimes return duplicates
        preunique_count = raw_citations.size
        raw_citations = raw_citations.inject({}) do |h, citation|
          h[citation[:uri]] = citation; h
        end
        puts "  Got #{raw_citations.size} citation details." if verbose
        dupCount = preunique_count - raw_citations.size
        puts "    (after filtering out #{dupCount} duplicates!)" if verbose and dupCount > 0
        existing = retrieval.citations.inject({}) do |h, citation|
          h[citation[:uri]] = citation; h
        end
    
        raw_citations.each do |uri, raw_citation|
          if existing.delete(uri).nil?
            begin
              citation = retrieval.citations.create(:uri => uri,
                :details => symbolize_keys_deeply(raw_citation))
            rescue
              raise if raise_on_error
              log_error("Unable to save #{raw_citation.inspect}")
              failed = true
            end
          end
        end
        existing.values.map(&:destroy)
        retrieval.reload.retrieved_at = DateTime.now.utc
      end
      retrieval.save!
    rescue
      raise if raise_on_error
      log_error("Unable to query")
      failed = true
    rescue Timeout::Error
      raise if raise_on_error
      log_error("Unable to query (timeout)")
      failed = true
    end

    unless failed
      history = retrieval.histories.find_or_create_by_year_and_month(retrieval.retrieved_at.year, retrieval.retrieved_at.month)
      history.citations_count = retrieval.total_citations_count
      history.save!
      puts "  Saved history[#{history.id}: #{history.year}, #{history.month}] = #{history.citations_count}" if verbose
    end
    failed
  end

  def symbolize_keys_deeply(h)
    result = h.symbolize_keys
    result.each do |k,v|
      result[k] = symbolize_keys_deeply(v) if v.is_a? Hash
    end
    result
  end

  def log_error(msg)
    puts "ERROR: #{msg}: #{$!}"
    $!.backtrace.map {|line| puts "   #{line.sub(RAILS_ROOT, '')}" }
  end
end
