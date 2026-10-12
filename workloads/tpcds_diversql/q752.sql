WITH sales_sample AS (
    SELECT
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10) -- sample 10 % of rows
    WHERE cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2002
    )
),

sales_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        SUM(s.cs_quantity)          AS total_quantity,
        SUM(s.cs_net_paid)          AS total_net_paid
    FROM sales_sample s
    JOIN catalog_page cp
        ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_catalog_page_id
),

returns_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        SUM(r.cr_return_quantity)   AS returned_quantity,
        SUM(r.cr_return_amount)     AS returned_amount
    FROM catalog_returns r
    JOIN catalog_page cp
        ON r.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON r.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cp.cp_catalog_page_id
),

pages_with_sales_no_returns AS (
    SELECT cp_id
    FROM (
        SELECT cp_catalog_page_id AS cp_id FROM sales_agg
    )
    EXCEPT
    SELECT cp_id
    FROM (
        SELECT cp_catalog_page_id AS cp_id FROM returns_agg
    )
),

promo_pages AS (
    SELECT DISTINCT cp.cp_catalog_page_id AS cp_id
    FROM catalog_page cp
    FULL OUTER JOIN catalog_sales cs
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_promo_id IS NOT NULL
),

combined AS (
    SELECT cp_id, 'SalesOnly' AS source
    FROM pages_with_sales_no_returns
    UNION ALL
    SELECT cp_id, 'PromoOnly' AS source
    FROM promo_pages
    WHERE cp_id NOT IN (SELECT cp_id FROM pages_with_sales_no_returns)
)
SELECT
    c.cp_id,
    c.source,
    s.total_quantity,
    s.total_net_paid,
    r.returned_quantity,
    r.returned_amount
FROM combined c
LEFT JOIN sales_agg s
    ON c.cp_id = s.cp_catalog_page_id
LEFT JOIN returns_agg r
    ON c.cp_id = r.cp_catalog_page_id
ORDER BY c.source, c.cp_id
OFFSET 0 LIMIT 100
