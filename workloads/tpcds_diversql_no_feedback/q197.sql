WITH src AS (
  SELECT
    d_sold.d_date AS sold_date,
    d_sold.d_year,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    w.w_warehouse_name,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_net_profit AS net_profit,
    (SELECT sum(inv2.inv_quantity_on_hand)
     FROM inventory inv2
     WHERE inv2.inv_item_sk = i.i_item_sk
       AND inv2.inv_warehouse_sk = w.w_warehouse_sk) AS total_inventory_qty,
    (SELECT max(ws2.ws_ext_sales_price)
     FROM web_sales ws2
     WHERE ws2.ws_item_sk = i.i_item_sk) AS max_web_sales_price
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
                     AND inv.inv_date_sk = d_sold.d_date_sk
  LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_sold_date_sk = d_sold.d_date_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE d_sold.d_year = 2001
    AND ca.ca_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND cs.cs_ext_sales_price > (SELECT avg(cs2.cs_ext_sales_price)
                                 FROM catalog_sales cs2)
)
SELECT
  sold_date,
  i_item_id,
  i_product_name,
  w_warehouse_name,
  quantity,
  ext_sales_price,
  net_profit,
  total_inventory_qty,
  max_web_sales_price,
  RANK() OVER (PARTITION BY i_category ORDER BY net_profit DESC) AS profit_rank,
  CASE WHEN net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM src
GROUP BY
  sold_date,
  i_item_id,
  i_product_name,
  w_warehouse_name,
  quantity,
  ext_sales_price,
  net_profit,
  total_inventory_qty,
  max_web_sales_price,
  i_category
HAVING sum(quantity) > 10
ORDER BY profit_rank
LIMIT 100
