{{ config(materialized='table') }}

with base as (
    select * from {{ ref('stg_crypto_prices') }}
),

lagged as (
    select
        asset_id,
        asset_name,
        asset_symbol,
        price_checked_at,
        price_usd,
        market_cap,
        total_volume,
        high_24h,
        low_24h,
        daily_change_percentage,
        -- Look up the price from the PREVIOUS row for this specific coin
        lag(price_usd) over (
            partition by asset_id 
            order by price_checked_at asc
        ) as prev_hour_price_usd
    from base
)

select
    asset_id,
    asset_name,
    asset_symbol,
    price_checked_at,
    price_usd,
    market_cap,
    total_volume,
    high_24h,
    low_24h,
    daily_change_percentage,
    
    -- Hour-over-Hour metrics
    round(price_usd - prev_hour_price_usd, 4) as hourly_price_change_usd,
    round(((price_usd - prev_hour_price_usd) / nullif(prev_hour_price_usd, 0)) * 100, 2) as hourly_price_change_pct,
    
    -- 24-Hour Rolling Moving Average
    avg(price_usd) over (
        partition by asset_id 
        order by price_checked_at 
        rows between 23 preceding and current row
    ) as rolling_24h_avg_price,

    -- 24-Hour Rolling Volatility (Standard Deviation)
    stddev(price_usd) over (
        partition by asset_id 
        order by price_checked_at 
        rows between 23 preceding and current row
    ) as rolling_24h_volatility_stddev,

    -- Market Cap Categorization
    case 
        when market_cap >= 100000000000 then 'Mega Cap (>$100B)'
        when market_cap >= 10000000000 then 'Large Cap ($10B-$100B)'
        else 'Mid/Small Cap (<$10B)'
    end as market_cap_tier,

    -- Signal Trigger
    case 
        when price_usd > prev_hour_price_usd then 'Bullish (Up)'
        when price_usd < prev_hour_price_usd then 'Bearish (Down)'
        else 'Neutral'
    end as hourly_trend_signal

from lagged