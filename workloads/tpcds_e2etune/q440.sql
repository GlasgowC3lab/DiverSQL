WITH store_ret_agg AS (
    SELECT
        r.r_reason_desc AS category,
        CAST(ss.ss_store_sk AS VARCHAR) AS sub_category,
        SUM(sr.sr_refunded_cash) AS metric1,
        SUM(sr.sr_net_loss) AS metric2,
        COUNT(*) AS metric3
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY r.r_reason_desc, ss.ss_store_sk
),
catalog_sales_agg AS (
    SELECT
        sm.sm_type AS category,
        sm.sm_carrier AS sub_category,
        SUM(cs.cs_net_paid) AS metric1,
        AVG(cs.cs_ext_discount_amt) AS metric2,
        COUNT(DISTINCT cs.cs_order_number) AS metric3
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_paid > 500
    GROUP BY sm.sm_type, sm.sm_carrier
)
SELECT category, sub_category, metric1, metric2, metric3
FROM (
    SELECT * FROM store_ret_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
) AS combined
ORDER BY metric1 DESC
LIMIT 100
