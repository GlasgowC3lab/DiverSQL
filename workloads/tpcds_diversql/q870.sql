WITH base_agg AS (
    SELECT
        c.c_customer_id,
        cp.cp_department,
        SUM(cs.cs_net_paid_inc_tax) AS sum_net_paid,
        COUNT(*) AS cnt
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    FULL OUTER JOIN (
        SELECT
            i.inv_item_sk,
            i.inv_quantity_on_hand,
            w.w_warehouse_sk,
            w.w_state
        FROM inventory i
        JOIN warehouse w
            ON i.inv_warehouse_sk = w.w_warehouse_sk
    ) wi
        ON wi.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_net_paid_inc_tax > 1000
      AND cp.cp_department = 'Electronics'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_upper_bound > 50000
    GROUP BY GROUPING SETS (
        (c.c_customer_id, cp.cp_department),
        (c.c_customer_id),
        (cp.cp_department)
    )
)
SELECT
    department,
    AVG(sum_net_paid) AS avg_sum_net_paid,
    SUM(cnt) AS total_transactions
FROM (
    SELECT
        cp_department AS department,
        sum_net_paid,
        cnt
    FROM base_agg
) agg
WHERE department NOT IN (
    SELECT cp2.cp_department
    FROM catalog_sales cs2
    JOIN catalog_page cp2
        ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE cs2.cs_net_paid_inc_tax < 500
)
GROUP BY department
HAVING SUM(cnt) > 10
ORDER BY avg_sum_net_paid DESC
LIMIT 100
