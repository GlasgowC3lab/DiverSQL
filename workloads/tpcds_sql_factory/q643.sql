WITH catalog_agg AS (
  SELECT
    cp.cp_department,
    p.p_channel_tv,
    SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY cp.cp_department, p.p_channel_tv
),
web_agg AS (
  SELECT
    'Web' AS cp_department,
    p.p_channel_tv,
    SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY p.p_channel_tv
)
SELECT
  department,
  channel_tv,
  total_profit,
  CASE WHEN total_profit >= 10000 THEN 'High' ELSE 'Low' END AS profit_category,
  RANK() OVER (PARTITION BY channel_tv ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT cp_department AS department, p_channel_tv AS channel_tv, total_profit
  FROM catalog_agg
  UNION ALL
  SELECT cp_department AS department, p_channel_tv AS channel_tv, total_profit
  FROM web_agg
) AS combined
ORDER BY channel_tv, profit_rank
