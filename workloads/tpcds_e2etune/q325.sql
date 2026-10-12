WITH monthly_ship_mode_returns AS (
    SELECT
        d_ret.d_year,
        d_ret.d_moy,
        sm.sm_type,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
        COUNT(DISTINCT p.p_promo_id) AS promotions_started,
        COUNT(DISTINCT s.s_store_id) AS stores_closed
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON d_ret.d_date_sk = p.p_start_date_sk
    LEFT JOIN store s ON d_ret.d_date_sk = s.s_closed_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY d_ret.d_year, d_ret.d_moy, sm.sm_type
)
SELECT
    d_year,
    d_moy,
    sm_type,
    total_returns,
    total_return_amount,
    avg_return_tax,
    total_net_loss,
    distinct_customers,
    promotions_started,
    stores_closed,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_moy ORDER BY total_return_amount DESC) AS rank_by_return_amount
FROM monthly_ship_mode_returns
WHERE total_return_amount > 1000
ORDER BY d_year, d_moy, rank_by_return_amount
