WITH store_sales_agg AS (
  SELECT
    s.s_state AS state,
    i.i_brand AS brand,
    'store' AS channel,
    d.d_year,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_quantity) AS quantity
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
  GROUP BY s.s_state, i.i_brand, d.d_year
),
catalog_sales_agg AS (
  SELECT
    cc.cc_state AS state,
    i.i_brand AS brand,
    'catalog' AS channel,
    d.d_year,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_quantity) AS quantity
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
  GROUP BY cc.cc_state, i.i_brand, d.d_year
),
web_sales_agg AS (
  SELECT
    ws_site.web_state AS state,
    i.i_brand AS brand,
    'web' AS channel,
    d.d_year,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_quantity) AS quantity
  FROM web_sales ws
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
  GROUP BY ws_site.web_state, i.i_brand, d.d_year
),
combined AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
brand_state_rank AS (
  SELECT
    state,
    channel,
    brand,
    net_profit,
    quantity,
    d_year,
    RANK() OVER (PARTITION BY state, channel ORDER BY net_profit DESC) AS brand_rank,
    SUM(net_profit) OVER (PARTITION BY state) AS state_total_profit,
    SUM(net_profit) OVER () AS grand_total_profit
  FROM combined
)
SELECT
  state,
  channel,
  brand,
  net_profit,
  quantity,
  brand_rank,
  net_profit / NULLIF(state_total_profit, 0) AS brand_share_of_state,
  state_total_profit / NULLIF(grand_total_profit, 0) AS state_share_of_total,
  d_year
FROM brand_state_rank
WHERE brand_rank <= 5
ORDER BY state, channel, brand_rank
