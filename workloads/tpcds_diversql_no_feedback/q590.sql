WITH combined AS (
    -- First sub‑query: sales based on sold date and monthly catalog pages
    SELECT
        dd.d_year AS year,
        dd.d_month_seq AS month_seq,
        cc.cc_name AS call_center_name,
        cp.cp_type AS page_type,
        cs.cs_ext_sales_price AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE dd.d_year = 2001
      AND dd.d_first_dom IN (2415325, 2415052)
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
            AND cp2.cp_description LIKE '%girls%'
      )
    UNION ALL
    -- Second sub‑query: sales based on ship date and quarterly catalog pages
    SELECT
        dd2.d_year AS year,
        dd2.d_month_seq AS month_seq,
        cc2.cc_name AS call_center_name,
        cp2.cp_type AS page_type,
        cs2.cs_ext_sales_price AS sales_amount
    FROM catalog_sales cs2
    JOIN date_dim dd2 ON cs2.cs_ship_date_sk = dd2.d_date_sk
    JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
    JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE dd2.d_year = 2001
      AND dd2.d_first_dom IN (2415325, 2415052)
      AND cc2.cc_state = 'CA'
      AND cp2.cp_type = 'quarterly'
      AND cp2.cp_catalog_page_id LIKE 'AAAAAAA%'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp3
          WHERE cp3.cp_catalog_page_sk = cp2.cp_catalog_page_sk
            AND cp3.cp_description LIKE '%girls%'
      )
),
agg AS (
    SELECT
        year,
        month_seq,
        call_center_name,
        page_type,
        SUM(sales_amount) AS total_sales
    FROM combined
    GROUP BY ROLLUP (year, month_seq, call_center_name, page_type)
)
SELECT
    year,
    month_seq,
    call_center_name,
    page_type,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY year, month_seq, call_center_name, page_type) AS rn
FROM agg
ORDER BY year, month_seq, call_center_name, page_type
LIMIT 100
