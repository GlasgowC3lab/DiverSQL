WITH
    store_sales_agg AS (
        SELECT
            ss_item_sk,
            SUM(ss_ext_sales_price) AS total_store_sales,
            SUM(ss_net_profit) AS total_store_profit,
            COUNT(*) AS store_cnt
        FROM store_sales
        GROUP BY ss_item_sk
    ),
    item_not_in_returns AS (
        SELECT i_item_sk FROM item
        EXCEPT
        SELECT wr_item_sk FROM web_returns
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(i.i_category, i.i_brand), ib.ib_upper_bound) AS rn,
    i.i_category,
    i.i_brand,
    ib.ib_upper_bound AS income_band,
    SUM(total_store_sales)                AS store_sales_amount,
    SUM(catalog_sales_price)              AS catalog_sales_amount,
    SUM(wr.wr_return_amt)                 AS total_return_amount,
    COUNT(DISTINCT base.order_number)     AS orders_cnt
FROM (
    SELECT
        COALESCE(s.ss_item_sk, cs.cs_item_sk)               AS item_sk,
        s.total_store_sales,
        cs.cs_ext_sales_price                             AS catalog_sales_price,
        cs.cs_order_number                               AS order_number,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_catalog_page_sk
    FROM store_sales_agg s
    FULL OUTER JOIN catalog_sales cs
        ON s.ss_item_sk = cs.cs_item_sk
) AS base
LEFT JOIN web_returns wr
    ON base.item_sk = wr.wr_item_sk
LEFT JOIN item i
    ON base.item_sk = i.i_item_sk
LEFT JOIN household_demographics hd_bill
    ON base.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship
    ON base.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_page cp
    ON base.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN customer c_bill
    ON base.cs_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer c_ship
    ON base.cs_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN customer_address ca_bill
    ON base.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_ship
    ON base.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE base.item_sk NOT IN (SELECT i_item_sk FROM item_not_in_returns)
GROUP BY GROUPING SETS (
    (i.i_category, ib.ib_upper_bound),
    (i.i_brand,    ib.ib_upper_bound)
)
ORDER BY COALESCE(i.i_category, i.i_brand), ib.ib_upper_bound
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
