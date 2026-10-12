WITH catalog_profit AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    p.p_promo_sk,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS catalog_net_profit
  FROM catalog_sales cs
  INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY cs.cs_item_sk, p.p_promo_sk, p.p_promo_name
),
web_profit AS (
  SELECT
    ws.ws_item_sk AS item_sk,
    p.p_promo_sk,
    p.p_promo_name,
    SUM(ws.ws_net_profit) AS web_net_profit
  FROM web_sales ws
  INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY ws.ws_item_sk, p.p_promo_sk, p.p_promo_name
),
combined_profit AS (
  SELECT
    cp.item_sk,
    cp.p_promo_sk,
    cp.p_promo_name,
    cp.catalog_net_profit,
    wp.web_net_profit,
    CASE 
      WHEN wp.web_net_profit = 0 THEN NULL
      ELSE cp.catalog_net_profit / wp.web_net_profit
    END AS profit_ratio
  FROM catalog_profit cp
  LEFT JOIN web_profit wp
    ON cp.item_sk = wp.item_sk
    AND cp.p_promo_sk = wp.p_promo_sk
)
SELECT
  item_sk,
  p_promo_name,
  catalog_net_profit,
  web_net_profit,
  profit_ratio,
  LAG(profit_ratio) OVER (PARTITION BY p_promo_name ORDER BY item_sk) AS prev_profit_ratio,
  profit_ratio - LAG(profit_ratio) OVER (PARTITION BY p_promo_name ORDER BY item_sk) AS profit_ratio_change
FROM combined_profit
WHERE profit_ratio IS NOT NULL
ORDER BY p_promo_name, profit_ratio DESC
LIMIT 100
