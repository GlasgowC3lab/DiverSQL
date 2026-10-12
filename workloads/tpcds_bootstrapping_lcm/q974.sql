SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sales_year,
    d_sold.d_quarter_name AS sales_quarter,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_closed_date
FROM call_center cc
JOIN catalog_sales cs
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_quarter_name
ORDER BY total_net_paid DESC
LIMIT 100
