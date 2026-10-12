WITH max_qty AS (
    SELECT MAX(sr_return_quantity) AS max_qty
    FROM store_returns
    WHERE sr_returned_date_sk = 2451987
),
joined AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_reversed_charge,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_college_count,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        CASE
            WHEN cd.cd_credit_rating = 'Excellent' THEN 'High'
            WHEN cd.cd_credit_rating = 'Good' THEN 'Medium'
            ELSE 'Low'
        END AS credit_category
    FROM store_returns sr
    FULL OUTER JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        sr.sr_returned_date_sk IN (2451987, 2451064, 2451175)                -- predicate 1
        AND sr.sr_reversed_charge > 10.00                                 -- predicate 2
        AND sr.sr_return_quantity >= 1                                    -- predicate 3
        AND cd.cd_purchase_estimate BETWEEN 3000 AND 8000                  -- predicate 4
        AND cd.cd_dep_college_count <= 3                                   -- predicate 5
        AND hd.hd_income_band_sk IS NOT NULL                               -- predicate 6
        AND sr.sr_return_quantity < (SELECT max_qty FROM max_qty)        -- scalar‑subquery comparison
),
ranked AS (
    SELECT
        sr_returned_date_sk,
        sr_return_quantity,
        sr_return_amt,
        credit_category,
        hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY sr_return_amt DESC) AS rn,
        RANK() OVER (ORDER BY sr_return_amt DESC) AS overall_rank
    FROM joined
)
SELECT
    sr_returned_date_sk,
    sr_return_quantity,
    sr_return_amt,
    credit_category,
    hd_buy_potential,
    rn,
    overall_rank
FROM ranked
WHERE rn <= 5                                 -- top‑k per group
ORDER BY hd_buy_potential, rn
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
