WITH unified_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS location_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_call_center_sk,
           cs_quantity,
           cs_net_paid,
           cs_net_profit,
           'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_warehouse_sk,
           ws_quantity,
           ws_net_paid,
           ws_net_profit,
           'web'
    FROM web_sales
),
sales_agg AS (
    SELECT d.d_year,
           d.d_quarter_seq,
           us.channel,
           COALESCE(s.s_state, cc.cc_state, w.w_state) AS state,
           SUM(us.quantity) AS total_quantity,
           SUM(us.net_paid) AS total_sales,
           SUM(us.net_profit) AS total_profit
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN store s ON us.location_sk = s.s_store_sk
    LEFT JOIN call_center cc ON us.location_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON us.location_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, d.d_quarter_seq, us.channel, COALESCE(s.s_state, cc.cc_state, w.w_state)
),
quarterly_growth AS (
    SELECT *,
           LAG(total_sales) OVER (PARTITION BY channel, state ORDER BY d_year, d_quarter_seq) AS prev_sales,
           CASE
               WHEN LAG(total_sales) OVER (PARTITION BY channel, state ORDER BY d_year, d_quarter_seq) IS NULL THEN NULL
               ELSE (total_sales - LAG(total_sales) OVER (PARTITION BY channel, state ORDER BY d_year, d_quarter_seq)) / NULLIF(LAG(total_sales) OVER (PARTITION BY channel, state ORDER BY d_year, d_quarter_seq), 0)
           END AS sales_qoq_growth
    FROM sales_agg
),
ranked_growth AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY channel, state ORDER BY sales_qoq_growth DESC) AS growth_rank
    FROM quarterly_growth
    WHERE sales_qoq_growth IS NOT NULL
)
SELECT d_year,
       d_quarter_seq,
       channel,
       state,
       total_sales,
       total_profit,
       total_quantity,
       prev_sales,
       sales_qoq_growth,
       growth_rank
FROM ranked_growth
WHERE growth_rank <= 5
ORDER BY channel, state, growth_rank
