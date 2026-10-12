WITH base AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ws.ws_sales_price,
        ws.ws_quantity AS ws_quantity,
        ca.ca_state,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ws.ws_ship_mode_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
    JOIN tpcds.customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
    WHERE cs.cs_call_center_sk IN (22, 26)
      AND hd.hd_income_band_sk = 13
      AND ws.ws_ship_mode_sk = 12
      AND cr.cr_return_quantity > 0
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_amount > 1000
              AND cr2.cr_return_quantity > 5
        )
),
agg AS (
    SELECT
        cs_bill_customer_sk,
        hd_buy_potential,
        SUM(cs_ext_sales_price)      AS total_sales,
        SUM(cr_return_amount)        AS total_return_amount,
        SUM(ws_sales_price)          AS total_web_sales,
        COUNT(*)                     AS order_cnt
    FROM base
    GROUP BY GROUPING SETS (
        (cs_bill_customer_sk, hd_buy_potential),
        (cs_bill_customer_sk),
        ()
    )
    HAVING SUM(cs_ext_sales_price) > 1000
)
SELECT
    cs_bill_customer_sk,
    hd_buy_potential,
    total_sales,
    total_return_amount,
    total_web_sales,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
