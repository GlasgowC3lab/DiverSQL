SELECT w.w_warehouse_id,
       w.w_city,
       CASE WHEN w.w_gmt_offset > 0 THEN 'Positive Offset'
            WHEN w.w_gmt_offset = 0 THEN 'Zero Offset'
            ELSE 'Negative Offset' END AS gmt_offset_category,
       ws.ws_quantity,
       ws.ws_sales_price,
       ws.ws_quantity * ws.ws_sales_price AS total_sales,
       ws.ws_ext_discount_amt + ws.ws_coupon_amt AS total_discount,
       ws.ws_net_paid - ws.ws_ext_tax AS net_paid_excluding_tax,
       CONCAT(w.w_state, '-', w.w_city) AS state_city,
       (ws.ws_ext_sales_price - ws.ws_ext_tax) / NULLIF(ws.ws_quantity, 0) AS avg_price_per_item,
       CASE WHEN ws.ws_quantity > 10 THEN 'Bulk'
            WHEN ws.ws_quantity BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Small' END AS order_size_category
FROM web_sales ws
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'SC'
  AND ws.ws_sold_date_sk = 2451103
  AND ws.ws_quantity > 79
