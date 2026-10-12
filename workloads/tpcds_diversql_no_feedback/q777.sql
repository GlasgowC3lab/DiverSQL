WITH return_stats AS (
    SELECT
        cr.cr_returned_date_sk AS date_key,
        d.d_year,
        'return' AS src,
        SUM(cr.cr_return_amount) AS amount,
        COUNT(*) AS cnt,
        CAST(NULL AS integer) AS ad_count,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_quarter_name IN ('1901Q3', '1904Q3')
      AND cr.cr_warehouse_sk IN (4, 12)
      AND NOT EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_creation_date_sk = cr.cr_returned_date_sk
      )
    GROUP BY cr.cr_returned_date_sk, d.d_year
),
web_stats AS (
    SELECT
        wp.wp_creation_date_sk AS date_key,
        d.d_year,
        'web' AS src,
        CAST(NULL AS decimal(7,2)) AS amount,
        CAST(NULL AS integer) AS cnt,
        wp.wp_max_ad_count AS ad_count,
        CAST(NULL AS decimal(7,2)) AS avg_return_amount
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
      AND wp.wp_autogen_flag = 'N'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_returned_date_sk = wp.wp_creation_date_sk
            AND cr.cr_return_quantity > 0
      )
)
SELECT * FROM return_stats
UNION ALL
SELECT * FROM web_stats
LIMIT 100
