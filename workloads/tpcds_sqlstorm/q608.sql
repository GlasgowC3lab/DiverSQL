WITH sales_data AS (
  SELECT 'store' AS channel,
         ss_sold_date_sk AS date_sk,
         ss_item_sk AS item_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         ss_store_sk AS store_sk,
         ss_promo_sk AS promo_sk,
         ss_customer_sk AS customer_sk
  FROM store_sales
  UNION ALL
  SELECT 'web' AS channel,
         ws_sold_date_sk AS date_sk,
         ws_item_sk AS item_sk,
         ws_quantity AS quantity,
         ws_net_paid AS net_paid,
         ws_net_profit AS net_profit,
         ws_web_page_sk AS store_sk,
         ws_promo_sk AS promo_sk,
         ws_bill_customer_sk AS customer_sk
  FROM web_sales
  UNION ALL
  SELECT 'catalog' AS channel,
         cs_sold_date_sk AS date_sk,
         cs_item_sk AS item_sk,
         cs_quantity AS quantity,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit,
         cs_call_center_sk AS store_sk,
         cs_promo_sk AS promo_sk,
         cs_bill_customer_sk AS customer_sk
  FROM catalog_sales
),
returns_data AS (
  SELECT 'store' AS channel,
         sr_returned_date_sk AS date_sk,
         sr_item_sk AS item_sk,
         sr_return_quantity AS quantity,
         sr_net_loss AS net_loss,
         sr_store_sk AS store_sk
  FROM store_returns
  UNION ALL
  SELECT 'web' AS channel,
         wr_returned_date_sk AS date_sk,
         wr_item_sk AS item_sk,
         wr_return_quantity AS quantity,
         wr_net_loss AS net_loss,
         wr_web_page_sk AS store_sk
  FROM web_returns
  UNION ALL
  SELECT 'catalog' AS channel,
         cr_returned_date_sk AS date_sk,
         cr_item_sk AS item_sk,
         cr_return_quantity AS quantity,
         cr_net_loss AS net_loss,
         cr_call_center_sk AS store_sk
  FROM catalog_returns
),
item_info AS (
  SELECT i_item_sk,
         i_item_id,
         i_product_name,
         i_category,
         i_brand,
         i_current_price,
         i_manufact,
         i_color
  FROM item
),
promo_latest AS (
  SELECT p_item_sk,
         p_promo_sk,
         p_discount_active,
         ROW_NUMBER() OVER (PARTITION BY p_item_sk ORDER BY p_end_date_sk DESC) AS rn
  FROM promotion
  WHERE p_discount_active = 'Y'
),
sales_agg AS (
  SELECT
    sd.channel,
    dd.d_year,
    dd.d_month_seq,
    ii.i_category,
    ii.i_brand,
    SUM(sd.quantity) AS total_quantity,
    SUM(sd.net_paid) AS total_net_paid,
    SUM(sd.net_profit) AS total_net_profit,
    COALESCE(SUM(rd.net_loss), 0) AS total_net_loss,
    COUNT(DISTINCT sd.customer_sk) AS distinct_customers,
    MAX(CASE WHEN pl.rn = 1 THEN pl.p_promo_sk END) AS latest_promo_sk
  FROM sales_data sd
  LEFT JOIN returns_data rd
    ON sd.channel = rd.channel
    AND sd.date_sk = rd.date_sk
    AND sd.item_sk = rd.item_sk
    AND COALESCE(sd.store_sk, -1) = COALESCE(rd.store_sk, -1)
  JOIN date_dim dd ON sd.date_sk = dd.d_date_sk
  JOIN item_info ii ON sd.item_sk = ii.i_item_sk
  LEFT JOIN promo_latest pl ON sd.item_sk = pl.p_item_sk AND pl.rn = 1
  GROUP BY sd.channel, dd.d_year, dd.d_month_seq, ii.i_category, ii.i_brand
),
ranked_sales AS (
  SELECT
    channel,
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    total_quantity,
    total_net_paid,
    total_net_profit,
    total_net_loss,
    distinct_customers,
    latest_promo_sk,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
  FROM sales_agg
)
SELECT
  rs.channel,
  CONCAT(CAST(rs.d_year AS VARCHAR), '-', LPAD(CAST(rs.d_month_seq AS VARCHAR), 2, '0')) AS year_month,
  rs.i_category,
  rs.i_brand,
  rs.total_quantity,
  rs.total_net_paid,
  rs.total_net_profit,
  rs.total_net_loss,
  rs.distinct_customers,
  COALESCE(rs.latest_promo_sk, -1) AS latest_promo_sk,
  rs.profit_rank,
  (rs.total_net_profit / NULLIF(rs.total_net_paid, 0)) AS profit_margin,
  CASE
    WHEN (rs.total_net_profit / NULLIF(rs.total_net_paid, 0)) > 0.2 THEN 'High'
    WHEN (rs.total_net_profit / NULLIF(rs.total_net_paid, 0)) > 0.1 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  CONCAT(rs.channel, ':', rs.i_brand) AS channel_brand,
  (SELECT SUM(s2.total_net_profit) FROM sales_agg s2 WHERE s2.channel = rs.channel) AS channel_total_profit
FROM ranked_sales rs
WHERE rs.profit_rank <= 5
ORDER BY rs.d_year DESC, rs.d_month_seq DESC, rs.profit_rank
