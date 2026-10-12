WITH returns_agg AS (
   SELECT
       wp.wp_type AS page_type,
       wp.wp_url AS page_url,
       COUNT(*) AS total_returns,
       SUM(wr.wr_return_amt) AS total_return_amount,
       AVG(wr.wr_return_tax) AS avg_return_tax,
       SUM(wr.wr_return_quantity) AS total_return_quantity
   FROM web_returns wr
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_type IN ('bi-annual', 'quarterly', 'monthly')
     AND wr.wr_returned_date_sk BETWEEN 2450815 AND 2451088
   GROUP BY wp.wp_type, wp.wp_url
), returns_ranked AS (
   SELECT
       page_type,
       page_url,
       total_returns,
       total_return_amount,
       avg_return_tax,
       total_return_quantity,
       RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
   FROM returns_agg
), inventory_agg AS (
   SELECT
       w.w_state AS state,
       w.w_city AS city,
       SUM(i.inv_quantity_on_hand) AS total_quantity,
       AVG(i.inv_quantity_on_hand) AS avg_quantity,
       COUNT(DISTINCT i.inv_item_sk) AS distinct_items
   FROM inventory i
   JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_country = 'United States'
   GROUP BY w.w_state, w.w_city
), inventory_ranked AS (
   SELECT
       state,
       city,
       total_quantity,
       avg_quantity,
       distinct_items,
       RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
   FROM inventory_agg
)
SELECT
   'WEB_RETURN' AS metric_category,
   page_type AS dimension,
   total_return_amount AS metric_value,
   revenue_rank AS metric_rank
FROM returns_ranked
WHERE total_return_amount > 1000
UNION ALL
SELECT
   'WAREHOUSE_INVENTORY' AS metric_category,
   state AS dimension,
   total_quantity AS metric_value,
   quantity_rank AS metric_rank
FROM inventory_ranked
WHERE total_quantity > 5000
ORDER BY metric_category, metric_value DESC
