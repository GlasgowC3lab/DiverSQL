WITH unified_sales AS (
  SELECT
    'store' AS channel,
    ss.ss_sold_date_sk AS sales_date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_store_sk AS store_sk,
    CAST(NULL AS INTEGER) AS catalog_page_sk,
    CAST(NULL AS INTEGER) AS web_page_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_coupon_amt AS coupon_amt,
    ss.ss_ext_tax AS ext_tax,
    d.d_year,
    d.d_quarter_seq,
    i.i_category AS category,
    i.i_item_id AS item_id,
    i.i_current_price AS current_price
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002

  UNION ALL

  SELECT
    'web' AS channel,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    CAST(NULL AS INTEGER),
    CAST(NULL AS INTEGER),
    ws.ws_web_page_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_coupon_amt,
    ws.ws_ext_tax,
    d.d_year,
    d.d_quarter_seq,
    i.i_category,
    i.i_item_id,
    i.i_current_price
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002

  UNION ALL

  SELECT
    'catalog' AS channel,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    CAST(NULL AS INTEGER),
    cs.cs_catalog_page_sk,
    CAST(NULL AS INTEGER),
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_coupon_amt,
    cs.cs_ext_tax,
    d.d_year,
    d.d_quarter_seq,
    i.i_category,
    i.i_item_id,
    i.i_current_price
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
),

promo_category AS (
  SELECT
    i.i_category AS category,
    MAX(p.p_promo_sk) AS latest_promo_sk
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  WHERE p.p_discount_active = 'Y'
  GROUP BY i.i_category
),

category_agg AS (
  SELECT
    channel,
    d_year,
    d_quarter_seq,
    category,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS txns,
    ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_quarter_seq ORDER BY SUM(net_profit) DESC) AS cat_rank
  FROM unified_sales
  GROUP BY channel, d_year, d_quarter_seq, category
  HAVING SUM(net_profit) > 0
),

item_max_profit AS (
  SELECT
    channel,
    d_year,
    d_quarter_seq,
    category,
    item_id,
    MAX(net_profit) AS max_item_profit
  FROM unified_sales
  GROUP BY channel, d_year, d_quarter_seq, category, item_id
),

store_quarter AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    d.d_year,
    d.d_quarter_seq,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_quantity) AS store_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY ss.ss_store_sk, d.d_year, d.d_quarter_seq
),

store_quarter_agg AS (
  SELECT
    d_year,
    d_quarter_seq,
    SUM(store_net_profit) AS total_store_net_profit,
    SUM(store_quantity) AS total_store_quantity,
    COUNT(DISTINCT store_sk) AS store_count
  FROM store_quarter
  GROUP BY d_year, d_quarter_seq
),

store_quarter_perf AS (
  SELECT
    sqa.d_year,
    sqa.d_quarter_seq,
    sqa.total_store_net_profit,
    sqa.total_store_quantity,
    sqa.store_count,
    LAG(sqa.total_store_net_profit) OVER (ORDER BY sqa.d_year, sqa.d_quarter_seq) AS prior_total_store_profit,
    CASE 
      WHEN LAG(sqa.total_store_net_profit) OVER (ORDER BY sqa.d_year, sqa.d_quarter_seq) IS NULL 
           OR LAG(sqa.total_store_net_profit) OVER (ORDER BY sqa.d_year, sqa.d_quarter_seq) = 0 
      THEN NULL
      ELSE (sqa.total_store_net_profit - LAG(sqa.total_store_net_profit) OVER (ORDER BY sqa.d_year, sqa.d_quarter_seq)) / LAG(sqa.total_store_net_profit) OVER (ORDER BY sqa.d_year, sqa.d_quarter_seq)
    END AS total_profit_growth
  FROM store_quarter_agg sqa
)

SELECT
  ca.channel,
  ca.d_year,
  ca.d_quarter_seq,
  ca.category,
  ca.total_net_profit,
  ca.total_quantity,
  ca.txns,
  ca.cat_rank,
  COALESCE(pc.latest_promo_sk, -1) AS latest_promo_sk,
  CASE WHEN ca.channel = 'store' THEN sqp.total_store_net_profit ELSE NULL END AS total_store_net_profit,
  CASE WHEN ca.channel = 'store' THEN sqp.total_store_quantity ELSE NULL END AS total_store_quantity,
  CASE WHEN ca.channel = 'store' THEN sqp.store_count ELSE NULL END AS store_count,
  CASE WHEN ca.channel = 'store' THEN sqp.prior_total_store_profit ELSE NULL END AS prior_total_store_profit,
  CASE WHEN ca.channel = 'store' THEN sqp.total_profit_growth ELSE NULL END AS total_profit_growth,
  CASE 
    WHEN ca.channel = 'store' AND sqp.total_profit_growth > 0.25 THEN 'High Growth'
    WHEN ca.channel = 'store' AND sqp.total_profit_growth BETWEEN 0 AND 0.25 THEN 'Moderate Growth'
    WHEN ca.channel = 'store' AND sqp.total_profit_growth <= 0 THEN 'Low/Negative Growth'
    ELSE NULL
  END AS growth_bucket,
  CONCAT(ca.channel, '-', ca.category) AS channel_category_key,
  CASE WHEN COALESCE(pc.latest_promo_sk, -1) = -1 THEN 'NoPromo' ELSE 'HasPromo' END AS promo_flag,
  (SELECT MAX(imp.max_item_profit) FROM item_max_profit imp WHERE imp.channel = ca.channel AND imp.category = ca.category AND imp.d_year = ca.d_year AND imp.d_quarter_seq = ca.d_quarter_seq) AS top_item_profit,
  CASE WHEN COALESCE((SELECT MAX(p.p_cost) FROM promotion p JOIN item i2 ON p.p_item_sk = i2.i_item_sk WHERE i2.i_category = ca.category AND p.p_discount_active = 'Y'), 0) > 10 THEN 1 ELSE 0 END AS has_high_cost_promo
FROM category_agg ca
LEFT JOIN promo_category pc ON ca.category = pc.category
LEFT JOIN store_quarter_perf sqp
  ON ca.channel = 'store' AND ca.d_year = sqp.d_year AND ca.d_quarter_seq = sqp.d_quarter_seq
WHERE ca.cat_rank <= 5
ORDER BY ca.d_year, ca.d_quarter_seq, ca.channel, ca.cat_rank
LIMIT 100
