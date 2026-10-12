SELECT
  region,
  category,
  channel,
  sum(net_profit) AS total_profit,
  sum(revenue) AS total_revenue,
  sum(net_profit) / nullif(sum(revenue), 0) AS profit_margin
FROM (
  SELECT
    s.s_state AS region,
    i.i_category AS category,
    'store' AS channel,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_sales_price AS revenue
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2000
    AND p.p_discount_active = 'Y'

  UNION ALL

  SELECT
    cc.cc_state AS region,
    i.i_category AS category,
    'catalog' AS channel,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_sales_price AS revenue
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2000
    AND p.p_discount_active = 'Y'

  UNION ALL

  SELECT
    w.web_state AS region,
    i.i_category AS category,
    'web' AS channel,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_sales_price AS revenue
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2000
    AND p.p_discount_active = 'Y'
) AS all_sales
GROUP BY region, category, channel
ORDER BY total_revenue DESC
LIMIT 100
