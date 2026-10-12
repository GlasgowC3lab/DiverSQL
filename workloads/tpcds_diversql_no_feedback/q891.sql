WITH aggregated AS (
    SELECT
        s.s_state AS s_state,
        i.i_brand AS i_brand,
        d1.d_year AS d_year,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d1.d_date_sk = inv.inv_date_sk
    JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk               -- second alias for ITEM
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                         AND cr.cr_refunded_customer_sk = c.c_customer_sk
                         AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
                         AND cr.cr_returned_date_sk = d1.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk   -- second alias for DATE_DIM
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                    AND ws.ws_sold_date_sk = d1.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                     AND wr.wr_returned_date_sk = d1.d_date_sk
                     AND wr.wr_order_number = ws.ws_order_number
    WHERE d1.d_year BETWEEN 2001 AND 2002
      AND EXISTS (
          SELECT 1 FROM reason r2
          WHERE r2.r_reason_sk = cr.cr_reason_sk
            AND r2.r_reason_desc LIKE '%damaged%'
      )
    GROUP BY CUBE (s.s_state, i.i_brand, d1.d_year)
    HAVING SUM(ss.ss_net_profit) > 0
),
ranked AS (
    SELECT
        s_state,
        i_brand,
        d_year,
        distinct_customers,
        distinct_items,
        total_store_profit,
        total_web_profit,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_store_profit DESC) AS state_rank
    FROM aggregated
)
SELECT
    s_state,
    i_brand,
    d_year,
    distinct_customers,
    distinct_items,
    total_store_profit,
    total_web_profit,
    state_rank
FROM ranked
WHERE state_rank <= 5
ORDER BY s_state, i_brand, d_year
LIMIT 100
