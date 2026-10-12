WITH base AS (
  SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    ws.ws_net_profit,
    ws.ws_order_number,
    i.i_units,
    i.i_brand_id,
    w.w_county,
    cd_ref.cd_dep_employed_count
  FROM catalog_returns cr
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE i.i_units IN ('Box', 'Ton')
    AND w.w_county = 'Walker County'
    AND cd_ref.cd_dep_employed_count >= 2
    AND ws.ws_net_profit > 0
    AND i.i_brand_id = 10008011
),
aggregated AS (
  SELECT
    w_warehouse_id,
    w_warehouse_name,
    i_item_sk,
    i_item_id,
    i_product_name,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt
  FROM base
  GROUP BY w_warehouse_id, w_warehouse_name, i_item_sk, i_item_id, i_product_name
  HAVING SUM(ws_net_profit) > 1000
     AND COUNT(DISTINCT ws_order_number) >= 5
)
SELECT
  w_warehouse_id,
  w_warehouse_name,
  i_item_sk,
  i_item_id,
  i_product_name,
  total_net_profit,
  order_cnt,
  RANK() OVER (PARTITION BY w_warehouse_id ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
WHERE i_item_sk NOT IN (
  SELECT cr_item_sk FROM catalog_returns WHERE cr_return_amount IS NULL
)
ORDER BY total_net_profit DESC
LIMIT 100
