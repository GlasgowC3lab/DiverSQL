WITH catalog_agg AS (
  SELECT
    cp.cp_department,
    p.p_channel_tv,
    SUM(cs.cs_ext_list_price) AS total_list_price,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_net_paid_inc_ship_tax BETWEEN 100 AND 1000
  GROUP BY cp.cp_department, p.p_channel_tv
),
web_agg AS (
  SELECT
    'Web' AS cp_department,
    p.p_channel_tv,
    SUM(ws.ws_ext_list_price) AS total_list_price,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_net_paid_inc_ship_tax BETWEEN 100 AND 1000
  GROUP BY p.p_channel_tv
)
SELECT
  department,
  channel_tv,
  total_list_price,
  distinct_items,
  CASE WHEN distinct_items >= 50 THEN 'Broad' ELSE 'Narrow' END AS assortment_type,
  RANK() OVER (PARTITION BY department ORDER BY total_list_price DESC) AS list_price_rank
FROM (
  SELECT cp_department AS department, p_channel_tv AS channel_tv, total_list_price, distinct_items FROM catalog_agg
  UNION ALL
  SELECT cp_department AS department, p_channel_tv AS channel_tv, total_list_price, distinct_items FROM web_agg
) v
ORDER BY department, list_price_rank
