WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS sale_date_sk,
           s.s_state AS state,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT cs.cs_sold_date_sk AS sale_date_sk,
           cc.cc_state AS state,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk AS sale_date_sk,
           w.w_state AS state,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           us.state,
           us.channel,
           SUM(us.net_paid) AS total_net_paid,
           SUM(us.net_profit) AS total_net_profit,
           SUM(us.quantity) AS total_quantity,
           COUNT(DISTINCT us.sale_date_sk) AS distinct_sales_days
    FROM unified_sales us
    JOIN date_dim d ON us.sale_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year,
             d.d_month_seq,
             us.state,
             us.channel
)
SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.state,
    sa.channel,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.total_quantity,
    sa.distinct_sales_days,
    RANK() OVER (PARTITION BY sa.d_year, sa.d_month_seq ORDER BY sa.total_net_paid DESC) AS revenue_rank,
    SUM(sa.total_net_paid) OVER (PARTITION BY sa.state) AS state_total_net_paid,
    ROUND(100.0 * sa.total_net_paid / SUM(sa.total_net_paid) OVER (PARTITION BY sa.d_year, sa.d_month_seq), 2) AS pct_of_monthly_revenue
FROM sales_agg sa
ORDER BY sa.d_year, sa.d_month_seq, revenue_rank
LIMIT 1000
