WITH top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(ss_total, 0) + COALESCE(cs_total, 0) + COALESCE(ws_total, 0) AS total_net_paid,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ss_total, 0) + COALESCE(cs_total, 0) + COALESCE(ws_total, 0) DESC) AS rn
    FROM
        customer c
        LEFT JOIN (
            SELECT ss_customer_sk, SUM(ss_net_paid) AS ss_total
            FROM store_sales
            GROUP BY ss_customer_sk
        ) ss ON c.c_customer_sk = ss.ss_customer_sk
        LEFT JOIN (
            SELECT cs_bill_customer_sk, SUM(cs_net_paid) AS cs_total
            FROM catalog_sales
            GROUP BY cs_bill_customer_sk
        ) cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN (
            SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS ws_total
            FROM web_sales
            GROUP BY ws_bill_customer_sk
        ) ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
        AND c.c_birth_year BETWEEN 1950 AND 1990
),
customer_details AS (
    SELECT
        tc.c_customer_sk,
        tc.c_customer_id,
        tc.total_net_paid,
        d.d_year,
        d.d_month_seq,
        CASE
            WHEN tc.total_net_paid IS NULL THEN 'NO_SALES'
            WHEN tc.total_net_paid > 100000 THEN 'VIP'
            ELSE 'NORMAL'
        END AS tier,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        COALESCE(c.c_email_address, 'unknown@unknown.com') AS email,
        (
            SELECT COUNT(*)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = tc.c_customer_sk
              AND ss2.ss_net_paid > 0
        ) AS store_txn_cnt,
        (
            SELECT MAX(ss2.ss_net_paid)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = tc.c_customer_sk
        ) AS max_store_sale,
        (
            SELECT AVG(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = tc.c_customer_sk
        ) AS avg_catalog_sale
    FROM
        top_customers tc
        INNER JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
        LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE
        tc.rn <= 10
),
joined_returns AS (
    SELECT
        cd.c_customer_sk,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_loss
    FROM
        customer cd
        LEFT JOIN store_returns sr ON cd.c_customer_sk = sr.sr_customer_sk
        LEFT JOIN catalog_returns cr ON cd.c_customer_sk = cr.cr_refunded_customer_sk
        LEFT JOIN web_returns wr ON cd.c_customer_sk = wr.wr_refunded_customer_sk
    GROUP BY
        cd.c_customer_sk
),
final AS (
    SELECT
        cd.c_customer_id,
        cd.full_name,
        cd.email,
        cd.total_net_paid,
        cd.tier,
        cd.d_year,
        cd.d_month_seq,
        COALESCE(jr.store_loss, 0) + COALESCE(jr.catalog_loss, 0) + COALESCE(jr.web_loss, 0) AS total_loss,
        CASE
            WHEN (COALESCE(jr.store_loss, 0) + COALESCE(jr.catalog_loss, 0) + COALESCE(jr.web_loss, 0)) > cd.total_net_paid * 0.5 THEN 'HIGH_RISK'
            ELSE 'LOW_RISK'
        END AS risk_category,
        ROW_NUMBER() OVER (PARTITION BY cd.tier ORDER BY cd.total_net_paid DESC) AS tier_rank,
        cd.total_net_paid - LAG(cd.total_net_paid) OVER (PARTITION BY cd.tier ORDER BY cd.total_net_paid DESC) AS diff_prev,
        cd.total_net_paid / NULLIF(COALESCE(jr.store_loss, 0) + COALESCE(jr.catalog_loss, 0) + COALESCE(jr.web_loss, 0), 0) AS loss_to_sales_ratio,
        cd.store_txn_cnt,
        cd.max_store_sale,
        cd.avg_catalog_sale
    FROM
        customer_details cd
        LEFT JOIN joined_returns jr ON cd.c_customer_sk = jr.c_customer_sk
    WHERE
        cd.tier IN ('VIP', 'NORMAL')
        AND (cd.max_store_sale IS NOT NULL OR cd.avg_catalog_sale IS NOT NULL)
        AND EXISTS (
            SELECT 1
            FROM store_sales ss_check
            WHERE ss_check.ss_customer_sk = cd.c_customer_sk
              AND ss_check.ss_quantity > 5
        )
)
SELECT *
FROM final
WHERE tier_rank <= 3
UNION ALL
SELECT
    'AGGREGATE' AS c_customer_id,
    'Aggregate Summary' AS full_name,
    NULL AS email,
    SUM(total_net_paid) AS total_net_paid,
    NULL AS tier,
    NULL AS d_year,
    NULL AS d_month_seq,
    SUM(total_loss) AS total_loss,
    NULL AS risk_category,
    NULL AS tier_rank,
    NULL AS diff_prev,
    NULL AS loss_to_sales_ratio,
    SUM(store_txn_cnt) AS store_txn_cnt,
    MAX(max_store_sale) AS max_store_sale,
    AVG(avg_catalog_sale) AS avg_catalog_sale
FROM final
