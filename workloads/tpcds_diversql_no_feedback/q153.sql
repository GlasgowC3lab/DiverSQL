WITH joined AS (
  SELECT
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    cs.cs_order_number,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    s.s_state,
    i.i_category,
    d1.d_year,
    p.p_promo_name,
    cp.cp_department,
    wp.wp_url
  FROM catalog_sales cs
  JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d1.d_date_sk
  LEFT JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
  LEFT JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
  LEFT JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
  LEFT JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
  LEFT JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d1.d_date_sk
  LEFT JOIN web_page wp ON wp.wp_customer_sk = c_bill.c_customer_sk
    AND wp.wp_creation_date_sk = d1.d_date_sk
  WHERE d1.d_year = 2000
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
),
aggregated AS (
  SELECT
    s_state,
    i_category,
    d_year,
    p_promo_name,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_quantity) AS total_quantity,
    SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(sr_return_quantity, 0)) AS total_return_qty,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
  FROM joined
  GROUP BY CUBE (s_state, i_category, d_year, p_promo_name)
)
SELECT
  s_state,
  i_category,
  d_year,
  p_promo_name,
  total_sales,
  total_quantity,
  total_returns,
  total_return_qty,
  distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS state_row_num
FROM aggregated
ORDER BY total_sales DESC, s_state
