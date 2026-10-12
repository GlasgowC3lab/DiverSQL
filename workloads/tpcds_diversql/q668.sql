WITH
    union_set AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            ss.ss_net_profit AS metric_amount,
            CONCAT(p.p_channel_dmail, '-', p.p_purpose) AS descriptor,
            cd.cd_gender AS category
        FROM tpcds.store_sales ss
        JOIN tpcds.promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        JOIN tpcds.customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE regexp_like(p.p_purpose, '^U')
          AND p.p_channel_dmail = (
                SELECT p2.p_channel_dmail
                FROM tpcds.promotion p2
                ORDER BY p2.p_promo_sk
                LIMIT 1
          )
    ),
    catalog_set AS (
        SELECT
            cr.cr_refunded_customer_sk AS customer_sk,
            cr.cr_return_amount AS metric_amount,
            cc.cc_name AS descriptor,
            sm.sm_type AS category
        FROM tpcds.catalog_returns cr
        JOIN tpcds.call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cr.cr_return_amount > 0
          AND regexp_like(sm.sm_type, 'OVER|NEXT')
          AND cc.cc_name LIKE '%Center%'
    ),
    union_all AS (
        SELECT * FROM union_set
        UNION DISTINCT
        SELECT * FROM catalog_set
    ),
    intersect_set AS (
        SELECT customer_sk FROM union_all
        INTERSECT
        SELECT cd_demo_sk FROM tpcds.customer_demographics
        WHERE cd_purchase_estimate > 5000
    ),
    except_set AS (
        SELECT sr_customer_sk FROM tpcds.store_returns
        WHERE sr_net_loss > 100
    ),
    final_customers AS (
        SELECT customer_sk FROM intersect_set
        EXCEPT
        SELECT sr_customer_sk FROM except_set
    )
SELECT
    fc.customer_sk,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_transactions,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    REGEXP_EXTRACT(CAST(ss.ss_promo_sk AS VARCHAR), '(\\d+)', 1) AS promo_sk_extracted
FROM final_customers fc
JOIN tpcds.store_sales ss
    ON fc.customer_sk = ss.ss_customer_sk
GROUP BY
    fc.customer_sk,
    REGEXP_EXTRACT(CAST(ss.ss_promo_sk AS VARCHAR), '(\\d+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
