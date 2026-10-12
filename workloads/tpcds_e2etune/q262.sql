WITH agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost) AS total_return_amount,
        AVG(cr.cr_store_credit) AS avg_store_credit,
        SUM(cr.cr_reversed_charge) AS total_reversed_charge,
        COUNT(*) AS return_count,
        AVG(ib.ib_upper_bound) AS avg_income_upper
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE d.d_year IN (2001, 2002)
      AND cr.cr_return_amount > 0
      AND cr.cr_fee > 5
      AND cd.cd_gender IS NOT NULL
    GROUP BY d.d_year, d.d_moy, cd.cd_gender
)
SELECT
    d_year,
    d_moy AS month,
    cd_gender AS gender,
    total_return_amount,
    avg_store_credit,
    total_reversed_charge,
    return_count,
    avg_income_upper,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_by_total,
    ROUND(100.0 * total_return_amount / SUM(total_return_amount) OVER (PARTITION BY d_year), 2) AS pct_of_year_total
FROM agg
ORDER BY d_year, rank_by_total
