WITH
    intersect_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        INTERSECT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    sampled_store_sales AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    base AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_order_number,
            cp.cp_department,
            sm.sm_type,
            wh.w_warehouse_name,
            hd_bill.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            r.r_reason_desc,
            s.s_store_name,
            wp.wp_type,
            cs.cs_net_paid,
            cr.cr_return_amount,
            ss.ss_net_paid AS store_net_paid,
            wr.wr_return_amt
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse wh
            ON cs.cs_warehouse_sk = wh.w_warehouse_sk
        JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship
            ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN income_band ib
            ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
        JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN sampled_store_sales ss
            ON ss.ss_item_sk = cs.cs_item_sk
        LEFT JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN web_returns wr
            ON wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
        LEFT JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
    )
SELECT
    department,
    ship_mode,
    warehouse,
    income_lower_bound,
    SUM(sales_amount)        AS total_sales,
    SUM(returns_amount)      AS total_returns,
    SUM(store_sales_amount)  AS total_store_sales,
    SUM(web_returns_amount)  AS total_web_returns
FROM (
    SELECT
        cp_department            AS department,
        sm_type                  AS ship_mode,
        w_warehouse_name         AS warehouse,
        ib_lower_bound           AS income_lower_bound,
        cs_net_paid              AS sales_amount,
        0.0                      AS returns_amount,
        0.0                      AS store_sales_amount,
        0.0                      AS web_returns_amount,
        cs_item_sk
    FROM base
    UNION DISTINCT
    SELECT
        cp_department,
        sm_type,
        w_warehouse_name,
        ib_lower_bound,
        0.0,
        cr_return_amount,
        0.0,
        0.0,
        cs_item_sk
    FROM base
    UNION DISTINCT
    SELECT
        cp_department,
        sm_type,
        w_warehouse_name,
        ib_lower_bound,
        0.0,
        0.0,
        store_net_paid,
        0.0,
        cs_item_sk
    FROM base
    UNION DISTINCT
    SELECT
        cp_department,
        sm_type,
        w_warehouse_name,
        ib_lower_bound,
        0.0,
        0.0,
        0.0,
        wr_return_amt,
        cs_item_sk
    FROM base
) agg
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = agg.cs_item_sk
)
GROUP BY department, ship_mode, warehouse, income_lower_bound
ORDER BY total_sales DESC
LIMIT 50
