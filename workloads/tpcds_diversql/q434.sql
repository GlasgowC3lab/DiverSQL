WITH
  sales_union AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      i.i_category AS category,
      cs.cs_order_number AS order_id,
      cs.cs_net_profit AS net_profit,
      CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level,
      cs.cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
  ),
  store_item_full AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      i.i_category AS category,
      ss.ss_ticket_number AS order_id,
      ss.ss_net_profit AS net_profit,
      CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level,
      ss.ss_sold_date_sk AS sold_date_sk
    FROM store_sales ss
    FULL OUTER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01' OR i.i_item_sk IS NULL
  ),
  combined AS (
    SELECT * FROM sales_union
    UNION ALL
    SELECT * FROM store_item_full
  ),
  ranked AS (
    SELECT
      c.item_sk,
      c.category,
      c.order_id,
      c.net_profit,
      c.profit_level,
      c.sold_date_sk,
      ROW_NUMBER() OVER (PARTITION BY c.category ORDER BY c.net_profit DESC) AS rn
    FROM combined c
    WHERE EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_item_sk = c.item_sk
        AND inv.inv_quantity_on_hand > 0
    )
  )
SELECT
  item_sk,
  category,
  order_id,
  net_profit,
  profit_level,
  sold_date_sk
FROM ranked
WHERE rn <= 5
ORDER BY category, net_profit DESC
LIMIT 100
