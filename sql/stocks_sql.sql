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