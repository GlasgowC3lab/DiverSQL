WITH
    cs_orders AS (
        SELECT cs_order_number,
               cs_net_profit,
               cs_ext_sales_price,
               cs_call_center_sk,
               cs_bill_cdemo_sk,
               cs_ship_cdemo_sk
        FROM catalog_sales
        WHERE cs_net_profit > 1000
    ),
    ss_orders AS (
        SELECT ss_ticket_number
        FROM store_sales
        WHERE ss_net_profit < 0
    ),
    filtered_orders AS (
        SELECT cs_order_number,
               cs_net_profit,
               cs_ext_sales_price,
               cs_call_center_sk,
               cs_bill_cdemo_sk,
               cs_ship_cdemo_sk
        FROM cs_orders
        EXCEPT
        SELECT ss_ticket_number,
               NULL,
               NULL,
               NULL,
               NULL,
               NULL
        FROM ss_orders
    ),
    years AS (
        SELECT 2020 AS year UNION ALL SELECT 2021 AS year
    ),
    cc_small AS (
        SELECT cc_call_center_sk, cc_name, cc_city
        FROM call_center
        WHERE cc_city = 'Fairview'
        LIMIT 5
    )
SELECT
    fo.cs_order_number,
    fo.cs_net_profit,
    SUM(fo.cs_ext_sales_price) AS total_ext_sales,
    cc1.cc_name AS call_center_name,
    cd_bill.cd_gender,
    cd_ship.cd_marital_status,
    s1.s_store_name,
    wr.wr_return_amt,
    y.year
FROM filtered_orders fo
JOIN cc_small cc1 ON fo.cs_call_center_sk = cc1.cc_call_center_sk
JOIN call_center cc2 ON fo.cs_call_center_sk = cc2.cc_call_center_sk
JOIN customer_demographics cd_bill ON fo.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON fo.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store_sales ss ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
JOIN store s1 ON ss.ss_store_sk = s1.s_store_sk
JOIN store s2 ON ss.ss_store_sk = s2.s_store_sk
JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd_bill.cd_demo_sk
JOIN web_returns wr2 ON wr2.wr_returning_cdemo_sk = cd_ship.cd_demo_sk
CROSS JOIN years y
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr_not
    WHERE wr_not.wr_order_number = fo.cs_order_number
)
GROUP BY
    fo.cs_order_number,
    fo.cs_net_profit,
    cc1.cc_name,
    cd_bill.cd_gender,
    cd_ship.cd_marital_status,
    s1.s_store_name,
    wr.wr_return_amt,
    y.year
ORDER BY total_ext_sales DESC
LIMIT 100
