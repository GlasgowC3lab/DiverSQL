WITH common_orders AS (
   SELECT ws.ws_order_number AS order_number
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND ws.ws_ext_ship_cost > 1000
     AND ws.ws_ext_list_price > 5000
   INTERSECT
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
     AND cr.cr_return_amount > 100
)
SELECT
    d.d_date,
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    cr.cr_return_amount,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    wsite.web_name,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_return_amount DESC) AS rn_return_amount,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_ext_sales_price DESC) AS sales_price_rank
FROM common_orders co
JOIN web_sales ws ON ws.ws_order_number = co.order_number
JOIN catalog_returns cr ON cr.cr_order_number = co.order_number
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE cd.cd_marital_status = 'M'
  AND hd.hd_vehicle_count >= 1
  AND wsite.web_gmt_offset = -6.00
  AND d.d_month_seq BETWEEN 1 AND 12
  AND ws.ws_ext_ship_cost BETWEEN 500 AND 3000
ORDER BY ws.ws_ext_sales_price DESC
LIMIT 100
