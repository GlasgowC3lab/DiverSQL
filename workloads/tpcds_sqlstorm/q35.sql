WITH categories AS (
   SELECT DISTINCT i_category
   FROM item
), raw_sales AS (
   SELECT ss_sold_date_sk AS sale_date_sk,
          ss_item_sk AS item_sk,
          ss_quantity AS quantity,
          ss_net_paid AS net_paid,
          ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales
   UNION ALL
   SELECT cs_sold_date_sk,
          cs_item_sk,
          cs_quantity,
          cs_net_paid,
          cs_net_profit,
          'catalog'
   FROM catalog_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_quantity,
          ws_net_paid,
          ws_net_profit,
          'web'
   FROM web_sales
), sales_with_date AS (
   SELECT rs.*,
          d.d_year,
          d.d_moy,
          i.i_category,
          i.i_item_id,
          i.i_product_name,
          i.i_current_price
   FROM raw_sales rs
   JOIN date_dim d ON rs.sale_date_sk = d.d_date_sk
   JOIN item i ON rs.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
), monthly_category_sales AS (
   SELECT
      i_category,
      d_year,
      d_moy,
      channel,
      SUM(quantity) AS total_quantity,
      SUM(net_paid) AS total_sales,
      SUM(net_profit) AS total_profit,
      AVG(i_current_price) AS avg_item_price,
      COUNT(DISTINCT item_sk) AS distinct_items_sold
   FROM sales_with_date
   GROUP BY i_category, d_year, d_moy, channel
), category_monthly_totals AS (
   SELECT
      c.i_category,
      COALESCE(mcs.d_year, 0) AS year,
      COALESCE(mcs.d_moy, 0) AS month,
      COALESCE(mcs.total_quantity, 0) AS total_quantity,
      COALESCE(mcs.total_sales, 0.0) AS total_sales,
      COALESCE(mcs.total_profit, 0.0) AS total_profit,
      COALESCE(mcs.avg_item_price, 0.0) AS avg_item_price,
      COALESCE(mcs.distinct_items_sold, 0) AS distinct_items_sold,
      SUM(COALESCE(mcs.total_profit, 0.0)) OVER (PARTITION BY c.i_category ORDER BY COALESCE(mcs.d_year,0), COALESCE(mcs.d_moy,0) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit,
      LAG(COALESCE(mcs.total_profit, 0.0)) OVER (PARTITION BY c.i_category ORDER BY COALESCE(mcs.d_year,0), COALESCE(mcs.d_moy,0)) AS prev_month_profit
   FROM categories c
   LEFT JOIN monthly_category_sales mcs
     ON c.i_category = mcs.i_category
), category_aggregates AS (
   SELECT
      i_category,
      SUM(total_quantity) AS agg_quantity,
      SUM(total_sales) AS agg_sales,
      SUM(total_profit) AS agg_profit,
      AVG(avg_item_price) AS avg_price,
      SUM(distinct_items_sold) AS agg_distinct_items,
      CASE WHEN SUM(total_profit) > (SELECT AVG(total_profit) FROM monthly_category_sales) THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
   FROM category_monthly_totals
   GROUP BY i_category
)
SELECT
   ca.i_category,
   ca.agg_quantity,
   ca.agg_sales,
   ca.agg_profit,
   ca.avg_price,
   ca.agg_distinct_items,
   ROW_NUMBER() OVER (ORDER BY ca.agg_profit DESC) AS profit_rank,
   ca.profit_category,
   CONCAT(ca.i_category, ' (', CAST(ROW_NUMBER() OVER (ORDER BY ca.agg_profit DESC) AS VARCHAR), ')') AS category_label,
   (SELECT MAX(i3.i_current_price)
    FROM item i3
    WHERE i3.i_category = ca.i_category
      AND i3.i_rec_end_date >= DATE '2000-12-31'
      AND i3.i_rec_start_date <= DATE '2000-12-31') AS latest_price_2000,
   COALESCE(NULLIF(ca.profit_category, ''), 'UNKNOWN') AS profit_category_nonnull
FROM category_aggregates ca
ORDER BY profit_rank
LIMIT 100
