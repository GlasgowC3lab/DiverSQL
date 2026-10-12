WITH unified_sales AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_ext_sales_price AS sales,
        cs_net_profit AS profit
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk AS date_sk,
        NULL AS call_center_sk,
        ss_store_sk AS store_sk,
        NULL AS web_page_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        ss_ext_sales_price AS sales,
        ss_net_profit AS profit
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk AS date_sk,
        NULL AS call_center_sk,
        NULL AS store_sk,
        ws_web_page_sk AS web_page_sk,
        ws_item_sk AS item_sk,
        ws_bill_customer_sk AS customer_sk,
        ws_ext_sales_price AS sales,
        ws_net_profit AS profit
    FROM web_sales
)
SELECT
    d.d_year,
    CASE 
        WHEN us.store_sk IS NOT NULL THEN s.s_state
        WHEN us.call_center_sk IS NOT NULL THEN cc.cc_state
        ELSE 'WEB'
    END AS region,
    i.i_category,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(us.sales) AS total_sales,
    SUM(us.profit) AS total_profit,
    COUNT(*) AS transaction_count
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
LEFT JOIN store s ON us.store_sk = s.s_store_sk
JOIN item i ON us.item_sk = i.i_item_sk
JOIN customer c ON us.customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY
    d.d_year,
    CASE 
        WHEN us.store_sk IS NOT NULL THEN s.s_state
        WHEN us.call_center_sk IS NOT NULL THEN cc.cc_state
        ELSE 'WEB'
    END,
    i.i_category,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY d.d_year, total_sales DESC
LIMIT 100
