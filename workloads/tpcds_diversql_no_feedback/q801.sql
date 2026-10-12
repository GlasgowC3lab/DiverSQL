WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    s.s_store_name,
    ws.ws_web_site_sk,
    COUNT(DISTINCT cs_sample.cs_order_number) AS cnt_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
    AVG(CASE WHEN hd_bill.hd_vehicle_count > 0 THEN hd_bill.hd_vehicle_count END) AS avg_vehicle_cnt
FROM cs_sample
JOIN customer c_bill
    ON cs_sample.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs_sample.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_bill
    ON cs_sample.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs_sample.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs_sample.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs_sample.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs_sample.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs_sample.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c_ship.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE s.s_state = 'CA'
  AND wsite.web_country = 'United States'
GROUP BY s.s_store_name, ws.ws_web_site_sk
HAVING COUNT(DISTINCT cs_sample.cs_order_number) > 5
ORDER BY total_profit DESC
LIMIT 100
