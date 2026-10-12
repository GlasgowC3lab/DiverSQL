WITH sales_cc AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_list_price,
        cs.cs_coupon_amt,
        cs.cs_net_profit,
        cs.cs_order_number,
        cc.cc_call_center_id,
        cc.cc_class,
        cc.cc_city,
        cc.cc_state
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    sc.cc_call_center_id,
    sc.cc_class,
    sc.cs_order_number,
    sc.cs_list_price,
    sc.cs_coupon_amt,
    sc.cs_net_profit,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY sc.cs_net_profit DESC) AS dept_profit_rank,
    ROW_NUMBER() OVER (ORDER BY sc.cs_net_profit DESC) AS overall_rank
FROM sales_cc sc
JOIN catalog_page cp
    ON sc.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    sc.cc_class IN ('small', 'medium')
    AND cp.cp_catalog_number BETWEEN 10 AND 20
    AND sc.cs_list_price > 50
    AND sc.cs_coupon_amt < 1000
    AND sc.cs_net_profit IS NOT NULL
ORDER BY dept_profit_rank, cp.cp_department
LIMIT 100
