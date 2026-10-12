WITH
    catalog_sales_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_catalog_page_sk,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_bill_hdemo_sk,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_quantity) AS total_quantity,
            AVG(hd.hd_vehicle_count) AS avg_vehicle_count
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE cp.cp_type = 'monthly'
          AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2451100
          AND cs.cs_quantity > 1
        GROUP BY cs.cs_item_sk, cs.cs_catalog_page_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_bill_hdemo_sk
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_sold_time_sk,
            SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
            COUNT(*) AS store_txn_cnt
        FROM store_sales ss
        WHERE ss.ss_net_paid_inc_tax > 10
        GROUP BY ss.ss_item_sk, ss.ss_sold_time_sk
    ),
    store_returns_agg AS (
        SELECT
            sr.sr_item_sk,
            SUM(sr.sr_refunded_cash) AS total_refunded_cash,
            SUM(sr.sr_net_loss) AS total_net_loss
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
        GROUP BY sr.sr_item_sk
    ),
    catalog_item_keys AS (
        SELECT DISTINCT cr.cr_item_sk AS item_sk
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        WHERE cr.cr_return_quantity > 0
    ),
    store_return_item_keys AS (
        SELECT DISTINCT sr.sr_item_sk AS item_sk
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
    ),
    intersect_items AS (
        SELECT item_sk FROM catalog_item_keys
        INTERSECT
        SELECT item_sk FROM store_return_item_keys
    ),
    item_latest_reason AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               r.r_reason_desc,
               lr.max_returned_time_sk
        FROM item i
        LEFT JOIN LATERAL (
            SELECT cr.cr_reason_sk,
                   MAX(cr.cr_returned_time_sk) AS max_returned_time_sk
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
            GROUP BY cr.cr_reason_sk
            ORDER BY max_returned_time_sk DESC
            LIMIT 1
        ) lr ON TRUE
        LEFT JOIN reason r ON r.r_reason_sk = lr.cr_reason_sk
    ),
    full_sales AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_time_sk,
            cs.total_net_paid,
            cs.total_quantity,
            cs.avg_vehicle_count,
            ss.store_net_paid_inc_tax,
            ss.store_txn_cnt,
            sr.total_refunded_cash,
            sr.total_net_loss
        FROM catalog_sales_agg cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        FULL OUTER JOIN (
            SELECT
                ss.ss_item_sk,
                ss.ss_sold_time_sk,
                ss.store_net_paid_inc_tax,
                ss.store_txn_cnt
            FROM store_sales_agg ss
            JOIN time_dim td2 ON ss.ss_sold_time_sk = td2.t_time_sk
        ) ss ON cs.cs_sold_time_sk = ss.ss_sold_time_sk
               AND cs.cs_item_sk = ss.ss_item_sk
        LEFT JOIN store_returns_agg sr ON cs.cs_item_sk = sr.sr_item_sk
    )
SELECT
    fs.cs_item_sk AS item_sk,
    i.i_product_name,
    SUM(fs.total_net_paid) AS sum_catalog_net_paid,
    SUM(fs.store_net_paid_inc_tax) AS sum_store_net_paid_inc_tax,
    SUM(fs.total_refunded_cash) AS sum_refunded_cash,
    COUNT(*) AS total_transactions,
    MAX(fs.avg_vehicle_count) AS max_vehicle_count
FROM full_sales fs
JOIN intersect_items ii ON fs.cs_item_sk = ii.item_sk
JOIN item i ON i.i_item_sk = fs.cs_item_sk
WHERE fs.total_quantity > 5
GROUP BY fs.cs_item_sk, i.i_product_name

UNION

SELECT
    ilr.i_item_sk AS item_sk,
    ilr.i_product_name,
    NULL AS sum_catalog_net_paid,
    NULL AS sum_store_net_paid_inc_tax,
    NULL AS sum_refunded_cash,
    NULL AS total_transactions,
    NULL AS max_vehicle_count
FROM item_latest_reason ilr
WHERE ilr.r_reason_desc IS NOT NULL

ORDER BY item_sk
LIMIT 100
