WITH sales_union AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_profit AS net_profit,
    i.i_item_desc,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_item_desc, '^[A-Za-z]+$')
    AND p.p_promo_name LIKE '%Discount%'
  UNION
  SELECT
    ws.ws_item_sk AS item_sk,
    ws.ws_promo_sk AS promo_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS net_profit,
    i.i_item_desc,
    p.p_promo_name
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_item_desc, '^[A-Za-z]+$')
    AND p.p_promo_name LIKE '%Discount%'
)
SELECT
  su.i_item_desc,
  su.p_promo_name,
  regexp_extract(su.p_promo_name, '(\\d+)', 1) AS promo_number,
  SUM(su.quantity) AS total_quantity,
  SUM(su.net_profit) AS total_net_profit,
  CASE WHEN SUM(su.net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_status,
  (SELECT max(inv.inv_quantity_on_hand)
   FROM inventory inv
   WHERE inv.inv_item_sk = su.item_sk) AS max_inventory_qty
FROM sales_union su
GROUP BY
  su.i_item_desc,
  su.p_promo_name,
  regexp_extract(su.p_promo_name, '(\\d+)', 1),
  su.item_sk
ORDER BY total_net_profit DESC
LIMIT 100
