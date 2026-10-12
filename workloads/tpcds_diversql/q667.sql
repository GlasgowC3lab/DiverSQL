WITH pages_without_returns AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    EXCEPT
    SELECT cr_catalog_page_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 20000101 AND 20001231
),
carrier_subset AS (
    SELECT DISTINCT sm_carrier
    FROM ship_mode
    WHERE sm_carrier IN ('BARIAN', 'GERMA', 'ORIENTAL')
),
base_agg AS (
    SELECT
        sm.sm_carrier,
        s.s_store_name,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(
            COALESCE(cr.cr_net_loss, 0) +
            COALESCE(sr.sr_net_loss, 0) +
            COALESCE(wr.wr_net_loss, 0)
        ) AS total_net_loss,
        AVG(
            COALESCE(cr.cr_return_amount, 0) +
            COALESCE(sr.sr_return_amt, 0) +
            COALESCE(wr.wr_return_amt, 0)
        ) AS avg_return_amount,
        (SELECT COUNT(*) FROM pages_without_returns) AS pages_without_returns_cnt
    FROM catalog_returns cr
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_carrier IN ('BARIAN', 'GERMA', 'ORIENTAL')
      AND s.s_state = 'CA'
    GROUP BY sm.sm_carrier, s.s_store_name
)
SELECT DISTINCT
    ba.sm_carrier,
    ba.s_store_name,
    ba.distinct_customers,
    ba.total_net_loss,
    ba.avg_return_amount,
    ba.pages_without_returns_cnt,
    d.extra_flag
FROM base_agg ba
CROSS JOIN (SELECT 'FLAG_X' AS extra_flag) AS d
CROSS JOIN carrier_subset cs
WHERE ba.sm_carrier = cs.sm_carrier
ORDER BY ba.total_net_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
