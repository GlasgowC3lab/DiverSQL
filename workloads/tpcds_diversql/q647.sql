WITH sales_cust AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        ib.ib_income_band_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450820
      AND ib.ib_lower_bound >= 50001
),
page_cust AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        ib.ib_income_band_sk
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wp.wp_web_page_id LIKE 'AAAAAAA%'
      AND ib.ib_upper_bound <= 100000
),
union_cust AS (
    SELECT c_customer_sk, c_email_address, ib_income_band_sk FROM sales_cust
    UNION
    SELECT c_customer_sk, c_email_address, ib_income_band_sk FROM page_cust
),
excluded_cust AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        ib.ib_income_band_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 1000
),
final_cust AS (
    SELECT c_customer_sk, c_email_address, ib_income_band_sk
    FROM union_cust
    EXCEPT
    SELECT c_customer_sk, c_email_address, ib_income_band_sk
    FROM excluded_cust
)
SELECT
    fc.c_customer_sk,
    fc.c_email_address,
    fc.ib_income_band_sk,
    COUNT(DISTINCT ws.ws_item_sk) OVER () AS distinct_items_sold,
    COUNT(DISTINCT w.w_warehouse_id) OVER () AS distinct_warehouses,
    ROW_NUMBER() OVER (ORDER BY fc.c_customer_sk) AS rn
FROM final_cust fc
FULL OUTER JOIN web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk
FULL OUTER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
ORDER BY fc.c_customer_sk
