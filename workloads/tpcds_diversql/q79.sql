WITH base AS (
   SELECT
     cr.cr_return_amount,
     cr.cr_return_quantity,
     cr.cr_refunded_customer_sk,
     cr.cr_item_sk,
     cr.cr_ship_mode_sk,
     ws.ws_ext_sales_price,
     ws.ws_order_number,
     ws.ws_sold_date_sk,
     c.c_first_name,
     c.c_last_name,
     c.c_customer_sk,
     cd.cd_gender,
     hd.hd_income_band_sk,
     i.i_item_id,
     i.i_product_name,
     sm.sm_ship_mode_id,
     wp.wp_image_count,
     ARRAY_AGG(i.i_item_id) OVER (PARTITION BY c.c_customer_sk) AS item_array
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE c.c_birth_year BETWEEN 1940 AND 1960
     AND cd.cd_gender = 'M'
     AND hd.hd_income_band_sk IN (1, 2, 3)
     AND i.i_current_price > 20
     AND sm.sm_type = 'AIR'
     AND wp.wp_image_count >= 3
     AND ws.ws_sold_date_sk >= 2450810
), agg AS (
   SELECT
     c_customer_sk,
     c_first_name,
     c_last_name,
     SUM(cr_return_amount) AS total_return_amount,
     SUM(ws_ext_sales_price) AS total_sales_amount,
     COUNT(DISTINCT ws_order_number) AS distinct_orders,
     ARRAY_AGG(DISTINCT i_item_id) AS item_list
   FROM base
   GROUP BY c_customer_sk, c_first_name, c_last_name
   HAVING SUM(cr_return_amount) > 100
)
SELECT
   a.c_customer_sk,
   a.c_first_name,
   a.c_last_name,
   a.total_return_amount,
   a.total_sales_amount,
   a.distinct_orders,
   itm AS item_id,
   (
     SELECT MAX(ws2.ws_sold_date_sk)
     FROM web_sales ws2
     WHERE ws2.ws_bill_customer_sk = a.c_customer_sk
   ) AS latest_sold_date_sk
FROM agg a
CROSS JOIN UNNEST(a.item_list) AS t(itm)
ORDER BY a.total_return_amount DESC
LIMIT 100
