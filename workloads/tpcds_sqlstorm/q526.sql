WITH combined_sales AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_net_profit,
           cs_quantity,
           'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit,
           ws_quantity,
           'web'
    FROM web_sales
),
sales_with_date AS (
    SELECT cs.sold_date_sk,
           cs.item_sk,
           cs.net_profit,
           cs.quantity,
           cs.channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_category,
           i.i_category_id,
           i.i_class,
           i.i_class_id,
           i.i_brand,
           i.i_brand_id
    FROM combined_sales cs
    JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
    JOIN item i ON cs.item_sk = i.i_item_sk
),
quarterly_agg AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           channel,
           SUM(net_profit) AS total_profit,
           SUM(quantity) AS total_quantity,
           AVG(net_profit) AS avg_profit_per_item
    FROM sales_with_date
    GROUP BY d_year, d_quarter_seq, i_category, channel
),
category_rank AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           channel,
           total_profit,
           total_quantity,
           avg_profit_per_item,
           RANK() OVER (PARTITION BY d_year, d_quarter_seq, i_category ORDER BY total_profit DESC) AS profit_rank
    FROM quarterly_agg
),
profit_lag AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           channel,
           total_profit,
           LAG(total_profit) OVER (PARTITION BY i_category, channel ORDER BY d_year, d_quarter_seq) AS prev_quarter_profit,
           total_profit - LAG(total_profit) OVER (PARTITION BY i_category, channel ORDER BY d_year, d_quarter_seq) AS profit_change
    FROM quarterly_agg
)
SELECT cur.d_year,
       cur.d_quarter_seq,
       cur.i_category,
       cur.channel,
       cur.total_profit,
       cur.total_quantity,
       cur.avg_profit_per_item,
       cur.profit_rank,
       lag_pl.prev_quarter_profit,
       lag_pl.profit_change,
       ROUND(cur.total_profit / NULLIF(lag_pl.prev_quarter_profit, 0) * 100, 2) AS profit_growth_pct
FROM category_rank cur
JOIN profit_lag lag_pl
  ON cur.d_year = lag_pl.d_year
 AND cur.d_quarter_seq = lag_pl.d_quarter_seq
 AND cur.i_category = lag_pl.i_category
 AND cur.channel = lag_pl.channel
WHERE cur.profit_rank <= 5
ORDER BY cur.d_year, cur.d_quarter_seq, cur.i_category, cur.profit_rank
