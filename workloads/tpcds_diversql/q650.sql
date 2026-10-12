WITH inv_cs AS (
   SELECT
       inv.inv_warehouse_sk,
       inv.inv_quantity_on_hand,
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_sold_time_sk,
       cs.cs_bill_addr_sk,
       cs.cs_ship_addr_sk,
       cs.cs_ship_mode_sk,
       cs.cs_warehouse_sk,
       cs.cs_list_price
   FROM inventory inv
   FULL OUTER JOIN catalog_sales cs
       ON inv.inv_warehouse_sk = cs.cs_warehouse_sk
      AND inv.inv_date_sk = cs.cs_sold_date_sk
),
joined_data AS (
   SELECT
       ic.cs_order_number,
       ic.cs_ext_sales_price,
       ic.cs_net_paid,
       ic.cs_net_profit,
       sm.sm_type,
       w.w_warehouse_name,
       t.t_hour,
       ca_bill.ca_state AS bill_state,
       ca_ship.ca_state AS ship_state,
       ic.inv_quantity_on_hand,
       ss.ss_quantity AS store_quantity,
       wr.wr_return_quantity,
       wp.wp_type,
       CASE WHEN ic.cs_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
       ic.cs_list_price
   FROM inv_cs ic
   LEFT JOIN time_dim t
       ON ic.cs_sold_time_sk = t.t_time_sk
   LEFT JOIN customer_address ca_bill
       ON ic.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN customer_address ca_ship
       ON ic.cs_ship_addr_sk = ca_ship.ca_address_sk
   LEFT JOIN ship_mode sm
       ON ic.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w
       ON ic.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_sales ss
       ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN web_returns wr
       ON wr.wr_returned_time_sk = t.t_time_sk
   LEFT JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE (t.t_sub_shift = 'evening' OR t.t_sub_shift IS NULL)
     AND (w.w_state = 'CA' OR w.w_state IS NULL)
     AND (sm.sm_type = 'AIR' OR sm.sm_type IS NULL)
     AND (ic.cs_list_price > 50 OR ic.cs_list_price IS NULL)
)
SELECT
    profit_flag,
    bill_state,
    sm_type,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_paid) AS avg_paid,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(inv_quantity_on_hand) AS total_inventory
FROM joined_data
WHERE ship_state = 'NY' OR ship_state IS NULL
GROUP BY ROLLUP (profit_flag, bill_state, sm_type)

UNION DISTINCT

SELECT
    profit_flag,
    bill_state,
    sm_type,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_paid) AS avg_paid,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(inv_quantity_on_hand) AS total_inventory
FROM joined_data
WHERE ship_state = 'TX' OR ship_state IS NULL
GROUP BY ROLLUP (profit_flag, bill_state, sm_type)

ORDER BY total_sales DESC
LIMIT 100
