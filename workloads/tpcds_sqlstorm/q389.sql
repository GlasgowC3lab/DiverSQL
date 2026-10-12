WITH unified_sales AS (
  SELECT
    d.d_date AS sale_date,
    'catalog' AS channel,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amount,
    CASE WHEN cs.cs_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS is_promo,
    cs.cs_bill_customer_sk AS customer_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001

  UNION ALL

  SELECT
    d.d_date AS sale_date,
    'store' AS channel,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amount,
    CASE WHEN ss.ss_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS is_promo,
    ss.ss_customer_sk AS customer_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001

  UNION ALL

  SELECT
    d.d_date AS sale_date,
    'web' AS channel,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount_amount,
    CASE WHEN ws.ws_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS is_promo,
    ws.ws_bill_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
),
aggregated AS (
  SELECT
    sale_date,
    channel,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(discount_amount) AS total_discount,
    SUM(is_promo) AS promo_sales_count,
    AVG(CASE WHEN net_paid > 0 THEN net_profit / net_paid END) AS avg_profit_margin,
    SUM(net_paid) / NULLIF(SUM(quantity), 0) AS avg_price_per_item,
    approx_distinct(customer_sk) AS unique_customers
  FROM unified_sales
  GROUP BY sale_date, channel
)
SELECT
  sale_date,
  channel,
  total_quantity,
  total_net_paid,
  total_net_profit,
  total_discount,
  promo_sales_count,
  avg_profit_margin,
  avg_price_per_item,
  unique_customers,
  (promo_sales_count * 100.0 / NULLIF(total_quantity, 0)) AS promo_qty_pct,
  (total_discount * 100.0 / NULLIF(total_net_paid + total_discount, 0)) AS discount_pct,
  RANK() OVER (PARTITION BY sale_date ORDER BY total_net_profit DESC) AS profit_rank_among_channels
FROM aggregated
ORDER BY sale_date, channel
