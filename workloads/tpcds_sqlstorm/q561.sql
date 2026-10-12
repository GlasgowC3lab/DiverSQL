WITH unified_sales AS (
    SELECT d.d_year,
           s.s_state,
           i.i_category,
           i.i_brand,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity,
           ss.ss_ext_discount_amt AS discount,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001

    UNION ALL

    SELECT d2.d_year,
           NULL AS s_state,
           i2.i_category,
           i2.i_brand,
           cs.cs_net_paid - cs.cs_ext_tax + cs.cs_coupon_amt AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_ext_discount_amt AS discount,
           cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
    WHERE d2.d_year BETWEEN 1999 AND 2001

    UNION ALL

    SELECT d3.d_year,
           NULL AS s_state,
           i3.i_category,
           i3.i_brand,
           ws.ws_net_paid AS net_profit,
           ws.ws_quantity AS quantity,
           ws.ws_ext_discount_amt AS discount,
           ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk
    JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
    WHERE d3.d_year BETWEEN 1999 AND 2001
), agg AS (
    SELECT d_year,
           s_state,
           i_category,
           i_brand,
           SUM(net_profit) AS total_profit,
           SUM(quantity) AS total_quantity,
           AVG(discount) AS avg_discount,
           COUNT(DISTINCT item_sk) AS distinct_items
    FROM unified_sales
    GROUP BY d_year, s_state, i_category, i_brand
    HAVING SUM(net_profit) > 0
)
SELECT d_year,
       s_state,
       i_category,
       i_brand,
       total_profit,
       total_quantity,
       avg_discount,
       distinct_items,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
WHERE total_quantity > 10
ORDER BY total_profit DESC
LIMIT 100
