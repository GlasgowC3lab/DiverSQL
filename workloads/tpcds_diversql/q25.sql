WITH cat AS (
        SELECT cr.cr_refunded_cdemo_sk AS cd_demo_sk,
               d.d_year
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        WHERE regexp_like(cd.cd_education_status, 'College')
          AND cd.cd_gender LIKE 'F%'
    ),
    store AS (
        SELECT sr.sr_cdemo_sk AS cd_demo_sk,
               d.d_year
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE regexp_like(cd.cd_education_status, 'College')
          AND cd.cd_gender LIKE 'F%'
    ),
    union_set AS (
        SELECT cd_demo_sk, d_year FROM cat
        UNION
        SELECT cd_demo_sk, d_year FROM store
    ),
    diff_set AS (
        SELECT cd_demo_sk, d_year FROM union_set
        EXCEPT
        SELECT cd_demo_sk, d_year FROM store
    )
SELECT t.cd_demo_sk,
       t.d_year,
       CONCAT('Year-', CAST(t.d_year AS VARCHAR)) AS year_label,
       t.cnt
FROM (
    SELECT cd_demo_sk,
           d_year,
           COUNT(*) AS cnt
    FROM diff_set
    GROUP BY cd_demo_sk, d_year
) t
ORDER BY t.d_year DESC,
         t.cd_demo_sk
LIMIT 100
