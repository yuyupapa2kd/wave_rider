class GlobalAssetCollector
  SOURCE = "yahoo_chart"

  def initialize(client: GlobalAssets::YahooChartClient.new, now: Time.current)
    @client = client
    @now = now
  end

  def collect!(trade_date:, snapshot_type:)
    GlobalAssets::Registry.assets.filter_map do |asset|
      collect_asset!(asset, trade_date: trade_date, snapshot_type: snapshot_type)
    rescue StandardError => error
      Rails.logger.warn("글로벌자산 수집 실패: #{asset.fetch(:name)} #{error.message}")
      nil
    end
  end

  private

  attr_reader :client, :now

  def collect_asset!(asset, trade_date:, snapshot_type:)
    quote = client.quote(asset.fetch(:symbol))
    snapshot = GlobalAssetSnapshot.find_or_initialize_by(
      trade_date: trade_date,
      snapshot_type: snapshot_type,
      asset_code: asset.fetch(:code)
    )

    snapshot.update!(
      category: asset.fetch(:category),
      category_position: asset.fetch(:category_position),
      position: asset.fetch(:position),
      name: asset.fetch(:name),
      price: quote.fetch(:price),
      change_value: quote.fetch(:change_value),
      change_rate: quote.fetch(:change_rate),
      source: SOURCE,
      source_symbol: asset.fetch(:symbol),
      captured_at: now,
      raw_payload: quote.fetch(:raw_payload)
    )
    snapshot
  end
end
