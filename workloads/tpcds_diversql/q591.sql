/* goal: Identify high‑profit web orders for 2001 in California, enriched with inventory availability, call‑center context, and website details. The query samples sales, pre‑aggregates inventory, filters with several predicates, applies a CASE profit tier, ranks profits per site, and keeps rows that have a related call‑center record. */
WITH
  -- Aggregate inventory per item and date
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
  ),
  -- Items sold that are not present in the inventory table (set subtraction)
  item_diff AS (
    SELECT ws_item_sk
    FROM (SELECT ws_item_sk FROM web_sales) ws
    EXCEPT
    SELECT inv_item_sk FROM inventory
  ),
  -- Sample a fraction of the sales fact table
  sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)   -- roughly 10 % of rows
  )
SELECT
  ws.ws_order_number,
  d_sold.d_date   AS sold_date,
  d_ship.d_date   AS ship_date,
  t.t_hour,
  ws.ws_quantity,
  ws.ws_net_profit,
  CASE
    WHEN ws.ws_net_profit > 1000 THEN 'HIGH'
    WHEN ws.ws_net_profit > 0    THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  inv_agg.total_qty_on_hand,
  ws_site.web_name,
  ROW_NUMBER() OVER (PARTITION BY ws_site.web_site_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM sampled_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN inv_agg
  ON ws.ws_item_sk = inv_agg.inv_item_sk
 AND ws.ws_sold_date_sk = inv_agg.inv_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001                                   -- filter 1: year
  AND t.t_hour BETWEEN 9 AND 17                               -- filter 2: business hours
  AND ws_site.web_state = 'CA'                                 -- filter 3: site state
  AND cc.cc_state = 'CA'                                       -- filter 4: call‑center state
  AND ws.ws_quantity > 5                                      -- filter 5: minimum quantity
  AND ws_site.web_company_id = 2                               -- filter 6: specific company
  AND EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_division = cc.cc_division
          AND cc2.cc_employees > 1000
      )                                                      -- correlated EXISTS
  AND ws.ws_item_sk IN (SELECT ws_item_sk FROM item_diff)      -- use the EXCEPT result
ORDER BY profit_rank
LIMIT 100
