WITH
  base AS (
    SELECT
      d_sold.d_year,
      d_sold.d_month_seq,
      i.i_category,
      i.i_brand,
      cd_bill.cd_marital_status,
      sm.sm_type,
      cc.cc_state,
      s.s_state,
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      wr.wr_return_amt,
      inv.inv_quantity_on_hand,
      CASE WHEN ws.ws_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
      inv_stats.warehouse_cnt
    FROM web_sales ws
      JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
      JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
      JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
      JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
      LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
      CROSS JOIN LATERAL (
        SELECT COUNT(*) AS warehouse_cnt
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
      ) AS inv_stats
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cd_bill.cd_marital_status = 'M'
      AND sm.sm_type = 'AIR'
      AND cc.cc_state = 'CA'
      AND s.s_state = 'CA'
  ),
  agg1 AS (
    SELECT
      d_year,
      d_month_seq,
      i_category,
      i_brand,
      profit_flag,
      SUM(ws_ext_sales_price) AS total_sales,
      AVG(ws_net_profit) AS avg_profit,
      COUNT(DISTINCT ws_order_number) AS order_cnt,
      SUM(wr_return_amt) AS total_returns,
      MAX(inv_quantity_on_hand) AS max_inventory,
      MAX(warehouse_cnt) AS max_warehouse_cnt,
      ROW_NUMBER() OVER (PARTITION BY i_category, i_brand ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM base
    GROUP BY d_year, d_month_seq, i_category, i_brand, profit_flag
  ),
  agg2 AS (
    SELECT
      d_year,
      CAST(NULL AS INTEGER) AS d_month_seq,
      i_category,
      i_brand,
      profit_flag,
      SUM(ws_ext_sales_price) AS total_sales,
      AVG(ws_net_profit) AS avg_profit,
      COUNT(DISTINCT ws_order_number) AS order_cnt,
      SUM(wr_return_amt) AS total_returns,
      MAX(inv_quantity_on_hand) AS max_inventory,
      MAX(warehouse_cnt) AS max_warehouse_cnt,
      ROW_NUMBER() OVER (PARTITION BY i_category, i_brand ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM base
    WHERE d_month_seq = 12
    GROUP BY d_year, i_category, i_brand, profit_flag
  ),
  union_agg AS (
    SELECT * FROM agg1
    UNION DISTINCT
    SELECT * FROM agg2
  )
SELECT
  d_year,
  d_month_seq,
  i_category,
  i_brand,
  profit_flag,
  total_sales,
  avg_profit,
  order_cnt,
  total_returns,
  max_inventory,
  max_warehouse_cnt
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY i_category, i_brand ORDER BY total_sales DESC) AS rnk
  FROM union_agg
) t
WHERE rnk <= 5
ORDER BY total_sales DESC
LIMIT 100
