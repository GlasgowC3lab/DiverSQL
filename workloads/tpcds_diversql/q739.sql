/*
Goal: Analyze combined store and web sales performance for the year 2001, broken down by store, household buying potential and income band, while incorporating catalog and web returns information, applying realistic filters, sampling, ranking and a subquery.
*/
WITH ss_sampled AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    s.s_store_name,
    hd.hd_buy_potential,
    ib.ib_income_band_sk,
    SUM(ss.ss_net_profit)               AS total_store_profit,
    AVG(ws.ws_net_paid)                 AS avg_web_paid,
    COUNT(DISTINCT c.c_customer_id)     AS unique_customers,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS row_num
FROM
    ss_sampled ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    /* Full outer join to keep all catalog return rows even when no matching store‑sale rows */
    FULL OUTER JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    d.d_year = 2001                                   -- filter by year
    AND s.s_state = 'CA'                               -- stores in California
    AND ib.ib_upper_bound <= 150000                    -- income band upper bound filter
    AND hd.hd_vehicle_count > 1                        -- households with more than one vehicle
    AND t.t_hour BETWEEN 9 AND 17                      -- business hours
    AND EXISTS (                                        -- only keep rows where the order has a loss‑making web return
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_net_loss > 0
    )
GROUP BY
    d.d_year,
    s.s_store_name,
    hd.hd_buy_potential,
    ib.ib_income_band_sk
ORDER BY
    total_store_profit DESC
LIMIT 100
