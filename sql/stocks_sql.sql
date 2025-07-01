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