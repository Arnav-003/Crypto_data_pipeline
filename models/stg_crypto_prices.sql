{{ config(materialized='view') }}
select
    id as asset_id,
    name as asset_name,
    symbol as asset_symbol,
    cast(price_checked_at as timestamp) as price_checked_at,
    cast(price_usd as float64) as price_usd,
    cast(market_cap as float64) as market_cap,
    cast(total_volume as float64) as total_volume,
    cast(high_24h as float64) as high_24h,
    cast(low_24h as float64) as low_24h,
    cast(price_change_percentage_24h as float64) as daily_change_percentage,
    -- Risk analytics: calculate the absolute dollar spread between the daily high and low
    (cast(high_24h as float64) - cast(low_24h as float64)) as intraday_dollar_spread
from {{ source('crypto_raw', 'raw_prices') }}
