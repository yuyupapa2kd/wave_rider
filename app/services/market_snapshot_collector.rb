class MarketSnapshotCollector
  MIN_TRADE_VALUE = 100_000_000_000
  MIN_CHANGE_RATE = 10

  class CollectionError < StandardError; end

  def initialize(client: Kiwoom::Client.new)
    @client = client
  end

  def collect!(trade_date:, snapshot_type:)
    snapshot = MarketSnapshot.find_or_create_by!(trade_date: trade_date, snapshot_type: snapshot_type)
    snapshot.update!(status: "collecting", started_at: Time.current, failure_message: nil)
    log!(snapshot, stage: "start", message: "수집 시작")

    unless @client.trading_day?(trade_date)
      snapshot.update!(status: "skipped", completed_at: Time.current, failure_message: "비거래일")
      log!(snapshot, stage: "trading_day", message: "비거래일로 수집 생략")
      return snapshot
    end

    collected_items = collect_items(snapshot, trade_date)
    raise CollectionError, "수집 가능한 종목 없음" if collected_items.empty?

    MarketSnapshot.transaction do
      snapshot.lock!
      snapshot.snapshot_items.destroy_all
      snapshot.leader_selections.destroy_all

      collected_items.each do |item|
        stock = Stock.find_or_initialize_by(ticker: item.fetch(:ticker))
        stock.name = item.fetch(:name)
        stock.market = item[:market]
        stock.save!

        snapshot_item = snapshot.snapshot_items.create!(
          stock: stock,
          trade_value: item.fetch(:trade_value),
          volume: item.fetch(:volume),
          current_price: item.fetch(:current_price),
          change_rate: item.fetch(:change_rate),
          raw_payload: item.fetch(:raw_payload)
        )

        item.fetch(:metrics).each do |metric|
          snapshot_item.daily_metrics.create!(
            metric_date: metric.fetch(:date),
            institution_net_purchase: metric.fetch(:institution),
            pension_net_purchase: metric.fetch(:pension),
            foreign_net_purchase: metric.fetch(:foreign),
            individual_net_purchase: metric.fetch(:individual),
            execution_strength: metric.fetch(:execution_strength),
            raw_investor_payload: metric.fetch(:raw_investor_payload),
            raw_strength_payload: metric.fetch(:raw_strength_payload)
          )
        end
      end

      snapshot.update!(
        status: "success",
        completed_at: Time.current,
        failed_at: nil,
        failure_message: nil
      )
    end

    log!(snapshot, stage: "complete", message: "수집 성공", details: { item_count: collected_items.size })
    snapshot
  rescue Kiwoom::ApiError => error
    fail_snapshot!(snapshot, error.message, stage: "kiwoom_api", error: error)
    raise
  rescue StandardError => error
    fail_snapshot!(snapshot, error.message, stage: "collector", error: error)
    raise
  end

  private

  def collect_items(snapshot, trade_date)
    candidates = @client.top_volume_candidates.first(100).select { |candidate| listing_candidate?(candidate) }
    candidates.filter_map do |candidate|
      candidate.merge(metrics: collect_metrics(candidate.fetch(:ticker), trade_date))
    rescue CollectionError => error
      log!(
        snapshot,
        level: "warn",
        stage: "metrics",
        message: error.message,
        details: { ticker: candidate.fetch(:ticker), name: candidate.fetch(:name) }
      )
      nil
    end
  end

  def listing_candidate?(candidate)
    candidate.fetch(:trade_value) >= MIN_TRADE_VALUE || candidate.fetch(:change_rate) >= MIN_CHANGE_RATE
  end

  def collect_metrics(ticker, trade_date)
    investor_rows = @client.investor_flows(ticker, trade_date)
    strength_rows = @client.daily_execution_strength(ticker)

    investor_by_date = investor_rows.index_by { |row| row.fetch(:date) }
    strength_by_date = strength_rows.index_by { |row| row.fetch(:date) }
    dates = strength_by_date.keys.select { |date| date <= trade_date }.sort.reverse.first(10)

    raise CollectionError, "#{ticker} 체결강도 10영업일 데이터 부족" if dates.size < 10

    dates.map do |date|
      investor = investor_by_date[date]
      strength = strength_by_date[date]
      raise CollectionError, "#{ticker} #{date} 매수주체 데이터 누락" if investor.blank?
      raise CollectionError, "#{ticker} #{date} 체결강도 데이터 누락" if strength.blank?

      {
        date: date,
        institution: investor.fetch(:institution),
        pension: investor.fetch(:pension),
        foreign: investor.fetch(:foreign),
        individual: investor.fetch(:individual),
        execution_strength: strength.fetch(:execution_strength),
        raw_investor_payload: investor.fetch(:raw_payload),
        raw_strength_payload: strength.fetch(:raw_payload)
      }
    end
  end

  def fail_snapshot!(snapshot, message, stage:, error:)
    return if snapshot.nil?

    snapshot.update!(
      status: "failed",
      failed_at: Time.current,
      failure_message: message.truncate(160)
    )
    log!(
      snapshot,
      level: "error",
      stage: stage,
      message: message,
      endpoint: error.respond_to?(:endpoint) ? error.endpoint : nil,
      api_id: error.respond_to?(:api_id) ? error.api_id : nil,
      response_code: error.respond_to?(:response_code) ? error.response_code : nil,
      details: error.respond_to?(:body) ? { body: error.body } : { class: error.class.name }
    )
  end

  def log!(snapshot, level: "info", stage:, message:, endpoint: nil, api_id: nil, response_code: nil, details: {})
    snapshot.collection_logs.create!(
      level: level,
      stage: stage,
      endpoint: endpoint,
      api_id: api_id,
      response_code: response_code,
      message: message,
      details: details || {},
      occurred_at: Time.current
    )
  end
end
