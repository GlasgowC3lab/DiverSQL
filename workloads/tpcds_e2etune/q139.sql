WITH filtered_returns AS (
    SELECT
        cr.cr_refunded_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity >= 10
      AND cr.cr_return_ship_cost > 100
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
),
aggregated AS (
    SELECT
        c.c_birth_country,
        hd.hd_vehicle_count,
        COUNT(DISTINCT fr.cr_refunded_customer_sk) AS distinct_customers,
        SUM(fr.cr_net_loss) AS total_net_loss,
        AVG(fr.cr_return_amount) AS avg_return_amount,
        SUM(fr.cr_return_quantity) AS total_return_quantity,
        SUM(fr.cr_store_credit) AS total_store_credit,
        ROUND(SUM(fr.cr_store_credit) / NULLIF(SUM(fr.cr_net_loss), 0), 2) AS store_credit_to_loss_ratio
    FROM filtered_returns fr
    JOIN customer c ON fr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_birth_country, hd.hd_vehicle_count
    HAVING SUM(fr.cr_net_loss) > 1000
)
SELECT
    a.c_birth_country,
    a.hd_vehicle_count,
    a.distinct_customers,
    a.total_net_loss,
    a.avg_return_amount,
    a.total_return_quantity,
    a.total_store_credit,
    a.store_credit_to_loss_ratio,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 10
