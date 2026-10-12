/* goal: Identify the highest net‑paid sales amount per return reason for customers that have at least two employed dependents, while excluding orders that have a large return amount, and enrich the result with the average net‑paid amount for the store of each sale. The query ranks the rows, applies a CASE flag for profit/loss, uses an anti‑join, a LATERAL sub‑query, and merges two filtered datasets with UNION DISTINCT. */
WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        ss.ss_store_sk,
        cd.cd_demo_sk,
        cd.cd_dep_employed_count,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        sm.sm_ship_mode_id,
        r.r_reason_desc,
        wr.wr_return_amt,
        wp.wp_web_page_id,
        wp.wp_rec_start_date,
        la.avg_store_net_paid
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN LATERAL (
        SELECT avg(ss2.ss_net_paid_inc_tax) AS avg_store_net_paid
        FROM tpcds.store_sales ss2
        WHERE ss2.ss_store_sk = ss.ss_store_sk
    ) la ON true
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND cd.cd_dep_employed_count >= 2
      AND cr.cr_return_quantity > 1
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_order_number = cr.cr_order_number
              AND cr2.cr_return_amount > 5000
        )
),
first_select AS (
    SELECT
        cd_demo_sk,
        r_reason_desc,
        ss_net_paid_inc_tax,
        CASE WHEN ss_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY ss_net_paid_inc_tax DESC) AS rn,
        avg_store_net_paid
    FROM base
    WHERE cr_return_amount < 2000
),
second_select AS (
    SELECT
        cd_demo_sk,
        r_reason_desc,
        ss_net_paid_inc_tax,
        CASE WHEN ss_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY ss_net_paid_inc_tax DESC) AS rn,
        avg_store_net_paid
    FROM base
    WHERE cr_return_amount >= 2000
)
SELECT
    cd_demo_sk,
    r_reason_desc,
    ss_net_paid_inc_tax,
    profit_flag,
    rn,
    avg_store_net_paid
FROM (
    SELECT cd_demo_sk, r_reason_desc, ss_net_paid_inc_tax, profit_flag, rn, avg_store_net_paid
    FROM first_select
    UNION DISTINCT
    SELECT cd_demo_sk, r_reason_desc, ss_net_paid_inc_tax, profit_flag, rn, avg_store_net_paid
    FROM second_select
) combined
WHERE rn = 1
ORDER BY ss_net_paid_inc_tax DESC
LIMIT 100
