WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
        TABLESAMPLE BERNOULLI (10)
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_call_center_sk NOT IN (
        SELECT cc2.cc_call_center_sk FROM call_center cc2 WHERE cc2.cc_state = 'TX'
    )
      AND cp.cp_department IS NOT NULL
    GROUP BY GROUPING SETS ((d.d_year, cp.cp_department), (d.d_year))
),
store_agg AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
        TABLESAMPLE BERNOULLI (10)
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
        SELECT 1 FROM reason r WHERE r.r_reason_desc = 'Customer Not Satisfied'
    )
    GROUP BY GROUPING SETS ((d.d_year, cd.cd_gender), (d.d_year))
),
combined AS (
    SELECT year, category, total_sales, avg_discount FROM catalog_agg
    UNION ALL
    SELECT year, category, total_sales, avg_discount FROM store_agg
)
SELECT
    c.year,
    c.category,
    c.total_sales,
    c.avg_discount,
    (
        SELECT SUM(sr.sr_return_amt)
        FROM store_returns sr
            JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        WHERE dr.d_year = c.year
    ) AS yearly_return_amount
FROM combined c
ORDER BY c.year DESC, c.total_sales DESC
LIMIT 100
