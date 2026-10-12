WITH agg AS (
    SELECT
        COALESCE(c.c_customer_id, 'UNKNOWN') AS customer_id,
        c.c_salutation,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(wp.wp_link_count) AS total_link_count,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(cd.cd_dep_employed_count) AS avg_emp_deps,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        MIN(wp.wp_rec_end_date) AS first_rec_end_date,
        MAX(wp.wp_rec_end_date) AS last_rec_end_date,
        ARRAY[SUM(wp.wp_link_count), SUM(wp.wp_char_count)] AS link_char_agg_array
    FROM customer c
    FULL OUTER JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_salutation = 'Mrs.'
        AND c.c_birth_year BETWEEN 1960 AND 1980
        AND cd.cd_marital_status = 'S'
        AND wp.wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
        AND wp.wp_link_count >= 12
    GROUP BY
        COALESCE(c.c_customer_id, 'UNKNOWN'),
        c.c_salutation,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    agg.customer_id,
    agg.c_salutation,
    agg.c_birth_year,
    agg.cd_gender,
    agg.cd_marital_status,
    agg.total_link_count,
    agg.total_char_count,
    agg.avg_emp_deps,
    agg.distinct_customers,
    agg.first_rec_end_date,
    agg.last_rec_end_date,
    CASE ord WHEN 1 THEN 'link' WHEN 2 THEN 'char' END AS metric_type,
    val AS metric_value
FROM agg
CROSS JOIN UNNEST(agg.link_char_agg_array) WITH ORDINALITY AS t(val, ord)
ORDER BY agg.total_link_count DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
