WITH sales AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
agg AS (
    SELECT d_year,
           d_month_seq,
           i_category,
           sum(net_paid) AS total_net_paid,
           sum(net_profit) AS total_net_profit,
           round(100.0 * sum(net_profit) / nullif(sum(net_paid), 0), 2) AS profit_margin_percent
    FROM sales
    WHERE d_year BETWEEN 1998 AND 2000
    GROUP BY d_year, d_month_seq, i_category
    HAVING sum(net_paid) > 100000
)
SELECT d_year,
       d_month_seq,
       i_category,
       total_net_paid,
       total_net_profit,
       profit_margin_percent,
       rank() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 100
