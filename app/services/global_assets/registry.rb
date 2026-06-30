module GlobalAssets
  module Registry
    CATEGORIES = [
      {
        key: "indices",
        label: "지수",
        assets: [
          { code: "nasdaq", name: "나스닥", symbol: "^IXIC" },
          { code: "dow_jones", name: "다우존스", symbol: "^DJI" },
          { code: "sp500", name: "S&P500", symbol: "^GSPC" },
          { code: "kospi", name: "코스피", symbol: "^KS11" },
          { code: "kospi200_futures", name: "코스피200 선물", symbol: "^KS200" },
          { code: "philly_sox", name: "필라델피아 반도체", symbol: "^SOX" }
        ]
      },
      {
        key: "commodities",
        label: "원자재",
        assets: [
          { code: "gold", name: "금", symbol: "GC=F" },
          { code: "silver", name: "은", symbol: "SI=F" },
          { code: "wti", name: "WTI", symbol: "CL=F" },
          { code: "natural_gas", name: "천연가스", symbol: "NG=F" },
          { code: "copper", name: "구리", symbol: "HG=F" },
          { code: "us_corn", name: "미국 옥수수", symbol: "ZC=F" }
        ]
      },
      {
        key: "fx",
        label: "외환",
        assets: [
          { code: "usd_krw", name: "원/달러", symbol: "KRW=X" },
          { code: "eur_usd", name: "유로/달러", symbol: "EURUSD=X" },
          { code: "gbp_usd", name: "파운드/달러", symbol: "GBPUSD=X" },
          { code: "usd_jpy", name: "엔/달러", symbol: "JPY=X" }
        ]
      },
      {
        key: "crypto",
        label: "가상화폐",
        assets: [
          { code: "bitcoin", name: "비트코인", symbol: "BTC-USD" },
          { code: "ethereum", name: "이더리움", symbol: "ETH-USD" },
          { code: "xrp", name: "리플", symbol: "XRP-USD" },
          { code: "solana", name: "솔라나", symbol: "SOL-USD" }
        ]
      }
    ].freeze

    module_function

    def assets
      CATEGORIES.flat_map.with_index do |category, category_index|
        category.fetch(:assets).map.with_index do |asset, asset_index|
          asset.merge(
            category: category.fetch(:key),
            category_label: category.fetch(:label),
            category_position: category_index,
            position: asset_index
          )
        end
      end
    end

    def display_groups(records)
      records_by_code = records.index_by(&:asset_code)

      CATEGORIES.map do |category|
        snapshots = category.fetch(:assets).filter_map do |asset|
          records_by_code[asset.fetch(:code)]
        end

        {
          key: category.fetch(:key),
          label: category.fetch(:label),
          snapshots: snapshots
        }
      end
    end
  end
end
