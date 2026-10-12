WITH filtered_cust AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_employed_count
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_employed_count >= 3
),
filtered_cat AS (
    SELECT
        cr.cr_refunded_cdemo_sk AS cd_demo_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_return_quantity
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
),
filtered_store AS (
    SELECT
        sr.sr_cdemo_sk AS cd_demo_sk,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_fee,
        sr.sr_return_quantity
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost < 500
),
aggregated AS (
    SELECT
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(cat.cr_return_amount) AS total_catalog_return_amount,
        AVG(st.sr_return_amt) AS avg_store_return_amount,
        COUNT(DISTINCT cd.cd_demo_sk) AS cnt_customers,
        SUM(CASE WHEN cat.cr_net_loss > 2000 THEN cat.cr_net_loss ELSE 0 END) AS high_loss_sum,
        (SELECT COUNT(*) FROM catalog_returns) AS total_catalog_rows
    FROM filtered_cust cd
    JOIN filtered_cat cat ON cat.cd_demo_sk = cd.cd_demo_sk
    JOIN filtered_store st ON st.cd_demo_sk = cd.cd_demo_sk
    GROUP BY CUBE(cd.cd_gender, cd.cd_credit_rating)
)
SELECT
    cd_gender,
    cd_credit_rating,
    total_catalog_return_amount,
    avg_store_return_amount,
    cnt_customers,
    high_loss_sum,
    total_catalog_rows,
    ROW_NUMBER() OVER (ORDER BY total_catalog_return_amount DESC) AS rn
FROM aggregated
ORDER BY total_catalog_return_amount DESC
LIMIT 100
