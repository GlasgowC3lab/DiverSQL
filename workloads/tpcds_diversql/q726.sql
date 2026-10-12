WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
),
aggregated AS (
    SELECT
        cc.cc_name AS cc_name,
        cc.cc_state AS cc_state,
        dr.d_year AS d_year,
        dr.d_month_seq AS d_month_seq,
        cd.cd_marital_status AS cd_marital_status,
        hd.hd_income_band_sk AS hd_income_band_sk,
        p.p_channel_demo AS p_channel_demo,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        MIN(dr.d_date) AS first_return_date,
        MAX(dr.d_date) AS last_return_date,
        CASE
            WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_return_amount) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_level
    FROM sampled_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    FULL OUTER JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_income_band_sk = 5
      AND p.p_channel_demo = 'N'
      AND cr.cr_return_amount > 100
      AND cc.cc_employees BETWEEN 50 AND 200
    GROUP BY
        cc.cc_name,
        cc.cc_state,
        dr.d_year,
        dr.d_month_seq,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        p.p_channel_demo
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_return_amount DESC) AS return_rank
    FROM aggregated
)
SELECT
    cc_name,
    cc_state,
    d_year,
    d_month_seq,
    cd_marital_status,
    hd_income_band_sk,
    p_channel_demo,
    total_return_amount,
    avg_return_qty,
    distinct_orders,
    first_return_date,
    last_return_date,
    return_level,
    return_rank
FROM ranked
WHERE return_rank <= 5

UNION

SELECT
    cc_name,
    cc_state,
    d_year,
    d_month_seq,
    cd_marital_status,
    hd_income_band_sk,
    p_channel_demo,
    total_return_amount,
    avg_return_qty,
    distinct_orders,
    first_return_date,
    last_return_date,
    return_level,
    return_rank
FROM ranked
WHERE d_year = 2002 AND return_rank <= 5

ORDER BY total_return_amount DESC
OFFSET 20 LIMIT 100
