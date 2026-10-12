WITH
  sales_agg AS (
    SELECT
      cp.cp_department,
      d.d_year,
      hd.hd_buy_potential,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS cnt_sales
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 1998
      AND d.d_weekend = 'N'
      AND hd.hd_vehicle_count >= 1
      AND cs.cs_quantity > (SELECT MAX(ws.ws_quantity) FROM web_sales ws)
    GROUP BY ROLLUP (cp.cp_department, d.d_year, hd.hd_buy_potential)
  ),
  inventory_agg AS (
    SELECT
      d.d_year,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d
      ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
  ),
  cs_only_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT ws.ws_order_number
    FROM web_sales ws
  ),
  cs_only_orders_year AS (
    SELECT
      d.d_year,
      COUNT(*) AS only_order_cnt
    FROM cs_only_orders o
    JOIN catalog_sales cs
      ON cs.cs_order_number = o.cs_order_number
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
  )
SELECT
  COALESCE(s.cp_department, 'ALL DEPARTMENTS') AS department,
  COALESCE(s.d_year, i.d_year, co.d_year) AS year,
  COALESCE(s.hd_buy_potential, 'ALL POTENTIAL') AS buy_potential,
  s.total_sales,
  s.cnt_sales,
  i.total_inventory,
  co.only_order_cnt
FROM sales_agg s
FULL OUTER JOIN inventory_agg i
  ON s.d_year = i.d_year
LEFT JOIN cs_only_orders_year co
  ON COALESCE(s.d_year, i.d_year) = co.d_year
LIMIT 100
