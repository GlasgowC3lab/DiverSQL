WITH
  inv_agg AS (
    SELECT
      inv_warehouse_sk AS inv_warehouse_sk,
      inv_date_sk AS inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
  ),
  agg_sales AS (
    SELECT
      d_ss.d_year AS d_year,
      s.s_store_id AS s_store_id,
      s.s_store_name AS s_store_name,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(cs.cs_net_profit) AS catalog_profit,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(COALESCE(inv_agg.total_qty, 0)) AS total_inventory,
      COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
    FROM store_sales ss
      JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
      JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
      JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
      LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_ss.d_date_sk
      LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
      LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
      LEFT JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
      LEFT JOIN inv_agg
        ON inv_agg.inv_date_sk = d_ss.d_date_sk
        AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
      LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ss.d_date_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
      LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
      LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ss.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
      LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
      LEFT JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    WHERE d_ss.d_year = 2001
      AND s.s_number_employees >= 250
      AND p_ss.p_discount_active = 'Y'
    GROUP BY d_ss.d_year, s.s_store_id, s.s_store_name
  )
SELECT
  d_year,
  s_store_id,
  s_store_name,
  store_profit,
  catalog_profit,
  web_profit,
  total_inventory,
  distinct_return_reasons,
  profit_rank
FROM (
  SELECT
    d_year,
    s_store_id,
    s_store_name,
    store_profit,
    catalog_profit,
    web_profit,
    total_inventory,
    distinct_return_reasons,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY store_profit DESC) AS profit_rank
  FROM agg_sales
) q
WHERE profit_rank <= 5
ORDER BY d_year, profit_rank
LIMIT 100
