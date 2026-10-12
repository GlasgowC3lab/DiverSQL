WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
),
sales_with_details AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        d.d_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_sold_time_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_name,
        t.t_time,
        LAG(ws.ws_net_profit) OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY d.d_date) AS prev_net_profit
    FROM sampled_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
returns_info AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        r.r_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%price%'
    GROUP BY wr.wr_order_number, r.r_reason_desc
),
store_returns_info AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        r.r_reason_desc AS store_return_reason
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),
sales_plus_returns AS (
    SELECT
        s.*,
        COALESCE(r.total_return_qty, 0) AS return_qty,
        COALESCE(r.total_return_amt, 0) AS return_amt,
        r.r_reason_desc AS web_return_reason,
        sr.sr_net_loss,
        sr.store_return_reason,
        lr.latest_reason
    FROM sales_with_details s
    LEFT JOIN returns_info r ON s.ws_order_number = r.wr_order_number
    LEFT JOIN store_returns_info sr ON sr.sr_customer_sk = s.ws_bill_customer_sk
        AND sr.sr_returned_date_sk = s.d_date_sk
    LEFT JOIN LATERAL (
        SELECT r2.r_reason_desc AS latest_reason
        FROM web_returns wr2
        JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE wr2.wr_order_number = s.ws_order_number
        ORDER BY wr2.wr_returned_date_sk DESC
        LIMIT 1
    ) lr ON true
),
final_agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(spr.ws_net_profit - spr.return_amt - spr.sr_net_loss) AS avg_net_profit_adj
    FROM sales_plus_returns spr
    JOIN income_band ib ON spr.hd_income_band_sk = ib.ib_income_band_sk
    WHERE spr.ws_ext_sales_price > 100
        AND spr.t_time BETWEEN 5 AND 12
        AND spr.prev_net_profit IS NOT NULL
        AND spr.web_return_reason IS NOT NULL
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    HAVING AVG(spr.ws_net_profit - spr.return_amt - spr.sr_net_loss) > 50
)
SELECT *
FROM final_agg
EXCEPT
SELECT *
FROM (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(spr.ws_net_profit) AS avg_net_profit
    FROM sales_with_details spr
    JOIN income_band ib ON spr.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
) AS other
