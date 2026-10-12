WITH
    ca_sampled AS (
        SELECT *
        FROM customer_address
        TABLESAMPLE BERNOULLI (10)
    ),
    catalog_agg AS (
        SELECT
            cr.cr_warehouse_sk AS warehouse_sk,
            cr.cr_reason_sk AS reason_sk,
            SUM(cr.cr_return_amount) AS total_catalog_return_amount,
            COUNT(*) AS cnt_catalog_returns
        FROM catalog_returns cr
        JOIN ca_sampled ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cc.cc_state = 'CA'
          AND w.w_gmt_offset = -6.00
          AND cp.cp_department = 'Electronics'
          AND r.r_reason_desc LIKE '%damage%'
          AND cr.cr_reason_sk IN (
                SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%damage%'
          )
        GROUP BY cr.cr_warehouse_sk, cr.cr_reason_sk
    ),
    store_agg AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            sr.sr_reason_sk AS reason_sk,
            SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
            SUM(sr.sr_return_amt) AS total_store_return_amount,
            COUNT(*) AS cnt_store_transactions
        FROM store_sales ss
        JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN ca_sampled ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
        JOIN ca_sampled ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE ss.ss_net_paid_inc_tax > 1000
          AND r.r_reason_desc LIKE '%damage%'
        GROUP BY ss.ss_store_sk, sr.sr_reason_sk
    ),
    web_agg AS (
        SELECT
            wr.wr_reason_sk AS reason_sk,
            SUM(wr.wr_return_amt) AS total_web_return_amount,
            COUNT(*) AS cnt_web_returns
        FROM web_returns wr
        JOIN ca_sampled ca3 ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_return_amt < 500
          AND r.r_reason_desc LIKE '%damage%'
        GROUP BY wr.wr_reason_sk
    ),
    intersect_reasons AS (
        SELECT reason_sk FROM catalog_agg
        INTERSECT
        SELECT reason_sk FROM web_agg
    )
SELECT
    i.reason_sk,
    ca.total_catalog_return_amount,
    ca.cnt_catalog_returns,
    w.w_warehouse_name,
    sa.total_store_sales,
    sa.total_store_return_amount,
    sa.cnt_store_transactions,
    wa.total_web_return_amount,
    wa.cnt_web_returns
FROM intersect_reasons i
JOIN catalog_agg ca ON i.reason_sk = ca.reason_sk
JOIN warehouse w ON ca.warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_agg sa ON i.reason_sk = sa.reason_sk
LEFT JOIN web_agg wa ON i.reason_sk = wa.reason_sk
ORDER BY ca.total_catalog_return_amount DESC
LIMIT 100
