WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        t.t_hour,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state,
        ca.ca_city,
        r.r_reason_desc,
        wp.wp_url,
        cp.cp_type,
        inv.inv_quantity_on_hand,
        -- create an array of two numeric metrics for UNNEST
        ARRAY[ss.ss_quantity, CAST(ss.ss_ext_sales_price AS double)] AS metrics
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr
        ON ss.ss_ticket_number = wr.wr_order_number
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 12
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%color%')
)
SELECT
    b.ss_ticket_number,
    b.d_date,
    b.ca_state,
    b.ca_city,
    b.ib_lower_bound,
    b.ib_upper_bound,
    b.cp_type,
    b.inv_quantity_on_hand,
    metric,
    ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.ss_net_profit DESC) AS rn_state_profit,
    RANK() OVER (ORDER BY b.ss_net_profit DESC) AS overall_profit_rank,
    SUM(b.ss_net_profit) OVER (
        PARTITION BY b.ca_state
        ORDER BY b.d_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS profit_7day_sum
FROM base b
CROSS JOIN UNNEST(b.metrics) AS u(metric)
WHERE b.ss_ticket_number NOT IN (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
)
ORDER BY b.ss_net_profit DESC
LIMIT 100
