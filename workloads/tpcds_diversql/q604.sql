WITH q1 AS (
    SELECT
        regexp_extract(d.d_date_id, '^AAAAAAA([A-Z])', 1) AS date_code,
        cd.cd_credit_rating,
        concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
        sum(cr.cr_return_amount) AS total_return_amount,
        count(*) AS cnt
    FROM catalog_returns cr
    FULL OUTER JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        regexp_like(d.d_date_id, '^AAAAAAA[AL]')
        AND cd.cd_credit_rating LIKE '%Risk%'
        AND cr.cr_return_amount > (
            SELECT max(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_return_tax < 50
        )
        AND EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_income_band_sk = 5
              AND hd2.hd_vehicle_count > 2
        )
    GROUP BY
        regexp_extract(d.d_date_id, '^AAAAAAA([A-Z])', 1),
        cd.cd_credit_rating,
        concat(cd.cd_gender, '-', cd.cd_marital_status)
),

q2 AS (
    SELECT
        regexp_extract(d.d_date_id, '^AAAAAAA([A-Z])', 1) AS date_code,
        cd.cd_credit_rating,
        concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
        sum(cr.cr_return_amount) AS total_return_amount,
        count(*) AS cnt
    FROM catalog_returns cr
    FULL OUTER JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_credit_rating LIKE 'Good%'
        AND d.d_same_day_lq > (
            SELECT min(d2.d_same_day_lq)
            FROM date_dim d2
            WHERE d2.d_year = 2001
        )
        AND regexp_like(d.d_date_id, '^AAAAAAA[DL]')
    GROUP BY
        regexp_extract(d.d_date_id, '^AAAAAAA([A-Z])', 1),
        cd.cd_credit_rating,
        concat(cd.cd_gender, '-', cd.cd_marital_status)
)

SELECT
    u.date_code,
    u.cd_credit_rating,
    sum(u.total_return_amount) AS agg_total_return_amount,
    sum(u.cnt) AS agg_cnt,
    max(u.gender_marital) AS example_gender_marital
FROM (
    SELECT date_code, cd_credit_rating, gender_marital, total_return_amount, cnt FROM q1
    UNION
    SELECT date_code, cd_credit_rating, gender_marital, total_return_amount, cnt FROM q2
) AS u
GROUP BY u.date_code, u.cd_credit_rating
ORDER BY agg_total_return_amount DESC
LIMIT 100
