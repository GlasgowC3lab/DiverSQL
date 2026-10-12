WITH category_sales AS (
    SELECT i.i_category,
           i.i_brand,
           i.i_color,
           i.i_item_id,
           SUM(ss.ss_quantity) AS total_qty,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           AVG(ss.ss_net_profit / NULLIF(ss.ss_net_paid, 0)) AS avg_profit_margin
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_color = 'red'
      AND i.i_category_id IN (1, 3)
      AND i.i_rec_end_date >= DATE '1999-01-01'
      AND i.i_rec_end_date < DATE '2002-01-01'
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_category, i.i_brand, i.i_color, i.i_item_id
),
ranked_sales AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS rn
    FROM category_sales
)
SELECT i_category,
       i_brand,
       i_color,
       i_item_id,
       total_qty,
       total_sales,
       total_profit,
       avg_profit_margin
FROM ranked_sales
WHERE rn <= 5
ORDER BY i_category, total_profit DESC
