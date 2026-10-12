SELECT ws.ws_order_number,
       i.i_product_name,
       ws.ws_quantity,
       ws.ws_sales_price,
       ws.ws_quantity * ws.ws_sales_price AS total_sales,
       CASE WHEN ws.ws_quantity > 52 THEN 'Large' ELSE 'Small' END AS quantity_category,
       CASE WHEN i.i_brand = 'importocorp #4                                    ' THEN i.i_brand ELSE 'Other' END AS brand_category,
       (ws.ws_ext_sales_price - ws.ws_ext_discount_amt) AS net_sales,
       ws.ws_net_paid * 1.1 AS net_paid_with_tax,
       CONCAT(i.i_color, '-', i.i_size) AS color_size
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE ws.ws_sold_date_sk = 2452190
  AND i.i_category = 'Shoes                                             '
