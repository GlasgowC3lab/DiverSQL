WITH intersect_customers AS (
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_date_id, '^AAAA.*CAA$')
      AND d.d_day_name LIKE 'F%'
    INTERSECT
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
      AND regexp_like(cd.cd_credit_rating, '^A[0-9]{2}$')
)
SELECT
    ic.sr_customer_sk,
    cd.cd_gender,
    cd.cd_education_status,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    CONCAT('Customer ', CAST(ic.sr_customer_sk AS varchar), ' : ', cd.cd_gender) AS customer_label,
    SUBSTRING(d2.d_date_id, 1, 4) AS date_prefix,
    REGEXP_EXTRACT(d2.d_date_id, '([A-Z]+)', 1) AS extracted_letters
FROM intersect_customers ic
JOIN store_returns sr ON ic.sr_customer_sk = sr.sr_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
GROUP BY
    ic.sr_customer_sk,
    cd.cd_gender,
    cd.cd_education_status,
    CONCAT('Customer ', CAST(ic.sr_customer_sk AS varchar), ' : ', cd.cd_gender),
    SUBSTRING(d2.d_date_id, 1, 4),
    REGEXP_EXTRACT(d2.d_date_id, '([A-Z]+)', 1)
ORDER BY total_return_amt_inc_tax DESC
LIMIT 100
