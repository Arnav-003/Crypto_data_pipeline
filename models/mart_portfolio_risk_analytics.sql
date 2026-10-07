{{ config(materialized='table') }}

with analytics as (
    select * from {{ ref('int_crypto_time_series') }}
),

totals as (
    select 
        price_checked_at,
        sum(market_cap) as total_market_cap,
        sum(total_volume) as total_market_volume
    from analytics
    group by 1
)

select
    a.price_checked_at,
    a.asset_name,
    a.asset_symbol,
    a.market_cap_tier,
    a.price_usd,
    a.rolling_24h_avg_price,
    a.rolling_24h_volatility_stddev,
    a.hourly_trend_signal,
    
    -- Market Share Percentages
    round((a.market_cap / nullif(t.total_market_cap, 0)) * 100, 2) as market_cap_dominance_pct,
    round((a.total_volume / nullif(t.total_market_volume, 0)) * 100, 2) as trading_volume_dominance_pct

from analytics a
join totals t on a.price_checked_at = t.price_checked_at