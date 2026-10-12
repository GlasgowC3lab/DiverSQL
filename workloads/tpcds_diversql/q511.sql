WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    cs.cs_order_number,
    cc.cc_name,
    w.w_warehouse_name,
    cd.cd_gender,
    cs.cs_net_profit,
    CASE
        WHEN cs.cs_net_profit >= 1000 THEN 'High'
        WHEN cs.cs_net_profit >= 100  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY w.w_state ORDER BY cs.cs_net_profit DESC) AS profit_rank_state,
    (
        SELECT SUM(i2.inv_quantity_on_hand)
        FROM inventory i2
        WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
    ) AS total_inventory_per_warehouse
FROM catalog_sales cs
RIGHT OUTER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN ss_sample ss
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cc.cc_country = 'United States'
    AND w.w_state = 'CA'
    AND cd.cd_education_status = 'Advanced Degree'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
ORDER BY profit_rank_state ASC, cs.cs_net_profit DESC
LIMIT 100
