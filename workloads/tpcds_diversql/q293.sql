WITH ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_ship_mode_sk,
        ws_promo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS sum_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_ext_sales_price > 500
      AND ws_quantity >= 1
    GROUP BY ws_bill_customer_sk, ws_ship_mode_sk, ws_promo_sk
)
SELECT
    sm.sm_type,
    p.p_promo_name,
    c.c_first_name,
    c.c_last_name,
    SUM(ws_agg.total_sales) AS total_sales,
    SUM(ws_agg.sum_profit) / NULLIF(SUM(ws_agg.sales_cnt), 0) AS avg_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(cr.cr_order_number) AS return_count,
    ROW_NUMBER() OVER (ORDER BY SUM(ws_agg.total_sales) DESC) AS row_num
FROM ws_agg
JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN customer c ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND sm.sm_contract = 'Ek'
  AND p.p_channel_dmail = 'Y'
  AND p.p_promo_sk = 15
  AND ca.ca_location_type = 'apartment'
  AND c.c_birth_year >= 1980
GROUP BY ROLLUP (sm.sm_type, p.p_promo_name, c.c_first_name, c.c_last_name)
ORDER BY total_sales DESC
LIMIT 100
