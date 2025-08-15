-- Daily returns
SELECT 
    symbol,
    date,
    close,
    LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS prev_close,
    ROUND(((close - LAG(close) OVER (PARTITION BY symbol ORDER BY date)) / LAG(close) OVER (PARTITION BY symbol ORDER BY date) * 100), 2) AS daily_return
FROM stock_prices
WHERE symbol = 'AAPL'
ORDER BY date DESC
LIMIT 10;

-- a 30-day moving average

SELECT 
    symbol,
    date,
    close,
    ROUND(AVG(close) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS moving_avg_30d
FROM stock_prices
WHERE symbol = 'AAPL'
ORDER BY date DESC
LIMIT 10;

-- For AAPL, compute the daily percentage return and find the 5 days with the highest absolute returns (indicating volatility).

WITH daily_changes AS (
SELECT 
	symbol,
	date,
	close,
	LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS prev_close
FROM stock_prices
WHERE symbol = 'AAPL'
)

SELECT 
    symbol,
    date,
    close,
    prev_close,
    ROUND(((close - prev_close) / prev_close * 100), 2) AS daily_return,
    ROUND(ABS((close - prev_close) / prev_close * 100), 2) AS abs_daily_return
FROM daily_changes
WHERE prev_close IS NOT NULL
ORDER BY abs_daily_return DESC
LIMIT 5;

-- Calculate AAPL’s daily price range (high - low) as a percentage of the closing price and find days where the range was more than 2 standard deviations above the 30-day average range.

With daily_ranges AS (
SELECT 
       symbol,
       date,
	   high,
       low,
       close,
       ROUND((high - low) / close * 100, 2) AS daily_range_pct,
       AVG((high - low) / close * 100) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS avg_range_30d,
       STDDEV((high - low) / close * 100) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS stddev_range_30d
    FROM stock_prices
    WHERE symbol = 'AAPL'
)

SELECT 
	symbol,
    date,
    daily_range_pct,
    avg_range_30d,
    stddev_range_30d
FROM daily_ranges
WHERE daily_range_pct > avg_range_30d + 2 * stddev_range_30d
AND stddev_range_30d IS NOT NULL
ORDER BY date DESC;

-- Find days for AAPL where the trading volume was at least 50% higher than the 10-day average volume, and the closing price was above the 10-day moving average (indicating potential breakout days).

WITH volume_and_ma AS (
    SELECT 
        symbol,
        date,
        close,
        volume,
        AVG(volume) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS avg_volume_10d,
        AVG(close) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS moving_avg_10d
    FROM stock_prices
    WHERE symbol = 'AAPL'
)
SELECT 
    symbol,
    date,
    close,
    volume,
    ROUND(avg_volume_10d, 0) AS avg_volume_10d,
    ROUND(moving_avg_10d, 2) AS moving_avg_10d,
    ROUND((volume / avg_volume_10d - 1) * 100, 2) AS volume_pct_above_avg
FROM volume_and_ma
WHERE volume > avg_volume_10d * 1.5
AND close > moving_avg_10d
AND avg_volume_10d IS NOT NULL
ORDER BY date DESC
LIMIT 10;

--  Identify days for AAPL where the opening price gapped up or down by more than 2% compared to the previous day’s close, and show the gap size and subsequent day’s return.

WITH price_gaps AS (
    SELECT 
        symbol,
        date,
        open,
        close,
        LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS prev_close,
        ROUND(((open - LAG(close) OVER (PARTITION BY symbol ORDER BY date)) / LAG(close) OVER (PARTITION BY symbol ORDER BY date) * 100), 2) AS gap_pct,
        ROUND(((close - open) / open * 100), 2) AS intraday_return
    FROM stock_prices
    WHERE symbol = 'AAPL'
)
SELECT 
    symbol,
    date,
    open,
    prev_close,
    gap_pct,
    intraday_return
FROM price_gaps
WHERE ABS(gap_pct) > 2 AND prev_close IS NOT NULL
ORDER BY ABS(gap_pct) DESC
LIMIT 10;

--  For AAPL, find days where the stock’s closing price outperformed its 5-day average closing price by more than 5%, and rank these days by the degree of outperformance within each year.

WITH relative_strength AS (
    SELECT 
        symbol,
        date,
        close,
        EXTRACT(YEAR FROM date) AS year,
        AVG(close) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS avg_close_5d,
        ROUND(((close / AVG(close) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) - 1) * 100), 2) AS outperformance_pct
    FROM stock_prices
    WHERE symbol = 'AAPL'
)
SELECT 
    symbol,
    date,
    year,
    close,
    ROUND(avg_close_5d, 2) AS avg_close_5d,
    outperformance_pct,
    RANK() OVER (PARTITION BY symbol, year ORDER BY outperformance_pct DESC) AS strength_rank
FROM relative_strength
WHERE outperformance_pct > 5 AND avg_close_5d IS NOT NULL
ORDER BY year DESC, outperformance_pct DESC
LIMIT 10;

-- For AAPL, compute the percentage drawdown from the highest closing price in the past 30 days for each day, and identify the top 5 days with the largest drawdowns.

WITH max_highs AS (
    SELECT 
        symbol,
        date,
        close,
        MAX(close) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS max_close_30d
    FROM stock_prices
    WHERE symbol = 'AAPL'
)
SELECT 
    symbol,
    date,
    close,
    max_close_30d,
    ROUND(((close / max_close_30d - 1) * 100), 2) AS drawdown_pct
FROM max_highs
WHERE max_close_30d IS NOT NULL
ORDER BY drawdown_pct ASC
LIMIT 5;