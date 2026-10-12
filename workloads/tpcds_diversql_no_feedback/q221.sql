WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_returned_date_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns
    GROUP BY sr_customer_sk, sr_returned_date_sk
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS cnt_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_sold_date_sk
),
 dummy AS (
    SELECT 1 AS grp UNION ALL SELECT 2
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d_ws.d_year,
    SUM(ws_agg.total_net_profit) AS yearly_profit,
    SUM(sr_agg.total_net_loss) AS yearly_loss,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(SUM(ws_agg.total_net_profit)) OVER (
        PARTITION BY ib.ib_income_band_sk
        ORDER BY d_ws.d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit,
    g.grp
FROM sr_agg
JOIN customer c
    ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN ws_agg
    ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sr
    ON sr_agg.sr_returned_date_sk = d_sr.d_date_sk
JOIN date_dim d_ws
    ON ws_agg.ws_sold_date_sk = d_ws.d_date_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN dummy g
WHERE d_sr.d_year = 2001
  AND ib.ib_lower_bound >= 50000
  AND hd.hd_vehicle_count >= 1
  AND c.c_customer_sk IN (
        SELECT sr_customer_sk
        FROM store_returns
        WHERE sr_return_amt > 5000
    )
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d_ws.d_year,
    g.grp
ORDER BY yearly_profit DESC, ib.ib_income_band_sk
LIMIT 100
