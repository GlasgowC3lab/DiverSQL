WITH avg_profit_by_income AS (
    SELECT ib.ib_income_band_sk,
           AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_net_profit IS NOT NULL
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    MIN(ss.ss_coupon_amt) AS min_coupon_amt,
    MAX(ws.wr_return_amt) AS max_return_amt
FROM household_demographics hd
RIGHT JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN web_returns ws
    ON ws.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN avg_profit_by_income ap
    ON ib.ib_income_band_sk = ap.ib_income_band_sk
WHERE hd.hd_buy_potential = '5001-10000'
  AND ss.ss_coupon_amt > 30.00
  AND ws.wr_return_ship_cost < 200.00
  AND ss.ss_net_profit > ap.avg_profit
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
