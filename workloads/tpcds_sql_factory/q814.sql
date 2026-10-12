WITH catalog_agg AS (
  SELECT
    cp.cp_department,
    p.p_channel_tv,
    SUM(cs.cs_net_paid_inc_tax) AS total_inc_tax,
    MAX(cs.cs_net_profit) AS max_profit
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY cp.cp_department, p.p_channel_tv
  HAVING SUM(cs.cs_net_paid_inc_tax) > 20000
),
web_agg AS (
  SELECT
    'Web' AS cp_department,
    p.p_channel_tv,
    SUM(ws.ws_net_paid_inc_tax) AS total_inc_tax,
    MAX(ws.ws_net_profit) AS max_profit
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY p.p_channel_tv
  HAVING SUM(ws.ws_net_paid_inc_tax) > 20000
)
SELECT
  department,
  channel_tv,
  total_inc_tax,
  max_profit,
  DENSE_RANK() OVER (PARTITION BY channel_tv ORDER BY max_profit DESC) AS profit_dense_rank
FROM (
  SELECT cp_department AS department, p_channel_tv AS channel_tv, total_inc_tax, max_profit FROM catalog_agg
  UNION ALL
  SELECT cp_department AS department, p_channel_tv AS channel_tv, total_inc_tax, max_profit FROM web_agg
) u
ORDER BY channel_tv, profit_dense_rank
