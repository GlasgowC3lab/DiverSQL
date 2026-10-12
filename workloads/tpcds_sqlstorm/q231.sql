WITH sales_facts AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_store_sk AS channel_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_promo_sk AS promo_sk,
    'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_call_center_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_promo_sk,
    'catalog'
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_web_page_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_promo_sk,
    'web'
  FROM web_sales ws
),
date_joined AS (
  SELECT
    sf.*,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq
  FROM sales_facts sf
  JOIN date_dim d ON sf.date_sk = d.d_date_sk
  WHERE d.d_year = 2000
),
item_joined AS (
  SELECT
    dj.*,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_class,
    i.i_color,
    i.i_size
  FROM date_joined dj
  JOIN item i ON dj.item_sk = i.i_item_sk
),
store_joined AS (
  SELECT
    ij.*,
    CASE
      WHEN ij.channel = 'store' THEN st.s_state
      WHEN ij.channel = 'catalog' THEN cc.cc_state
      ELSE NULL
    END AS state,
    CASE
      WHEN ij.channel = 'store' THEN st.s_store_name
      WHEN ij.channel = 'catalog' THEN cc.cc_name
      ELSE NULL
    END AS channel_name
  FROM item_joined ij
  LEFT JOIN store st ON ij.channel = 'store' AND ij.channel_sk = st.s_store_sk
  LEFT JOIN call_center cc ON ij.channel = 'catalog' AND ij.channel_sk = cc.cc_call_center_sk
),
promo_joined AS (
  SELECT
    sj.*,
    p.p_promo_name,
    p.p_discount_active
  FROM store_joined sj
  LEFT JOIN promotion p ON sj.promo_sk = p.p_promo_sk
),
aggregated AS (
  SELECT
    state,
    i_category,
    i_brand,
    i_item_id,
    sum(quantity) AS total_qty,
    sum(net_paid) AS total_net_paid,
    sum(net_profit) AS total_net_profit,
    sum(discount_amt) AS total_discount,
    avg(CASE WHEN net_paid > 0 THEN discount_amt / net_paid ELSE 0 END) AS avg_discount_rate,
    count(DISTINCT promo_sk) AS distinct_promos_used,
    sum(CASE WHEN p_discount_active = 'Y' THEN discount_amt ELSE 0 END) AS promo_discount_total
  FROM promo_joined
  WHERE state IS NOT NULL
  GROUP BY GROUPING SETS (
    (state, i_category, i_brand, i_item_id),
    (state, i_category, i_brand),
    (state, i_category),
    (state)
  )
)
SELECT
  state,
  i_category,
  i_brand,
  i_item_id,
  total_qty,
  total_net_paid,
  total_net_profit,
  total_discount,
  round(avg_discount_rate, 4) AS avg_discount_rate,
  distinct_promos_used,
  promo_discount_total,
  rank() OVER (PARTITION BY state ORDER BY total_net_profit DESC) AS profit_rank,
  round(total_net_profit / nullif(total_net_paid, 0) * 100, 2) AS profit_margin_percent
FROM aggregated
ORDER BY state, profit_rank
LIMIT 200
