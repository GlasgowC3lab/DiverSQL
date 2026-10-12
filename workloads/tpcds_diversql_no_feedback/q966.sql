WITH returns_union AS (
    SELECT
        d.d_date,
        i.i_category,
        r.r_reason_desc,
        cr.cr_return_amount,
        i.i_item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_amount > 50
      AND r.r_reason_id LIKE 'AAAAAAAA%'

    UNION ALL

    SELECT
        d.d_date,
        i.i_category,
        r.r_reason_desc,
        cr.cr_return_amount,
        i.i_item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 70
      AND r.r_reason_id LIKE 'AAAAAAAAB%'
),
year_dim AS (
    SELECT d_year
    FROM date_dim
    WHERE d_year IN (2000, 2001)
)
SELECT
    ru.d_date,
    ru.i_category,
    ru.r_reason_desc,
    ru.cr_return_amount * yd.d_year AS amount_by_year,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = ru.i_item_sk
    ) AS total_item_returns
FROM returns_union ru
CROSS JOIN year_dim yd
ORDER BY amount_by_year DESC
LIMIT 100
