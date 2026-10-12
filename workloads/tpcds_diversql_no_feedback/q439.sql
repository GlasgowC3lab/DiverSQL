WITH sales_with_demo AS (
   SELECT
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_ext_sales_price,
       ws.ws_ext_discount_amt,
       ws.ws_ext_ship_cost,
       ws.ws_coupon_amt,
       hd_bill.hd_income_band_sk AS bill_income_band,
       hd_bill.hd_vehicle_count   AS bill_vehicle_count,
       hd_ship.hd_income_band_sk AS ship_income_band,
       hd_ship.hd_vehicle_count   AS ship_vehicle_count
   FROM web_sales ws
   JOIN household_demographics hd_bill
     ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   WHERE ws.ws_ext_ship_cost > 600
     AND ws.ws_ext_list_price BETWEEN 2000 AND 20000
     AND ws.ws_coupon_amt < 1000
     AND hd_bill.hd_vehicle_count >= 0
     AND hd_bill.hd_income_band_sk IN (2, 4, 8, 9)
     AND hd_ship.hd_vehicle_count >= 0
     AND hd_ship.hd_income_band_sk IN (2, 4, 8, 9)
)
SELECT
    bill_income_band,
    ship_income_band,
    grouping(bill_income_band, ship_income_band) AS grp_id,
    COUNT(*)                         AS order_cnt,
    SUM(ws_ext_sales_price)          AS total_sales,
    AVG(ws_ext_discount_amt)         AS avg_discount,
    MIN(ws_ext_ship_cost)            AS min_ship_cost,
    MAX(ws_ext_ship_cost)            AS max_ship_cost,
    SUM(sales_tax)                   AS total_sales_tax
FROM (
    SELECT
        swd.*,
        lt.sales_tax
    FROM sales_with_demo swd
    CROSS JOIN LATERAL (
        SELECT swd.ws_ext_sales_price * 0.05 AS sales_tax
    ) lt
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = swd.ws_item_sk
          AND ws2.ws_ext_sales_price > swd.ws_ext_sales_price
    )
) t
GROUP BY GROUPING SETS (
    (bill_income_band, ship_income_band),
    (bill_income_band),
    (ship_income_band),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
