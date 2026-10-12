WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r1
        ON cr.cr_reason_sk = r1.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE
        cc.cc_state = 'CA'                     -- predicate 1
        AND w.w_state = 'CA'                    -- predicate 2
        AND wp.wp_type = 'product'              -- predicate 3 (example value)
        AND cd.cd_gender = 'M'                  -- predicate 4
        AND ss.ss_sales_price > 100             -- predicate 5
    GROUP BY
        cc.cc_call_center_id,
        cd.cd_gender
),
intersect_orders AS (
    SELECT COUNT(*) AS intersect_order_count
    FROM (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
        INTERSECT
        SELECT wr.wr_order_number
        FROM web_returns wr
        WHERE wr.wr_return_amt > 0
    ) io
),
except_orders AS (
    SELECT COUNT(*) AS except_order_count
    FROM (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
        EXCEPT
        SELECT wr.wr_order_number
        FROM web_returns wr
        WHERE wr.wr_return_amt > 0
    ) eo
)
SELECT
    ROW_NUMBER() OVER (ORDER BY (b.total_catalog_return + b.total_web_return) DESC) AS rn,
    b.cc_call_center_id,
    b.cd_gender,
    b.total_catalog_return,
    b.total_web_return,
    (b.total_catalog_return + b.total_web_return) AS total_combined_return,
    i.intersect_order_count,
    e.except_order_count,
    lc.call_center_tax_pct
FROM base b
CROSS JOIN intersect_orders i
CROSS JOIN except_orders e
CROSS JOIN LATERAL (
    SELECT cc.cc_tax_percentage AS call_center_tax_pct
    FROM call_center cc
    WHERE cc.cc_call_center_id = b.cc_call_center_id
) lc
WHERE (b.total_catalog_return + b.total_web_return) > 1000
ORDER BY total_combined_return DESC
LIMIT 100
