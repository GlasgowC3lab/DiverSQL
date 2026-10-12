WITH sales_union AS (
    -- Catalog sales branch
    SELECT
        d.d_year,
        i.i_brand,
        i.i_item_sk,
        d.d_date_sk,
        cs.cs_quantity * cs.cs_sales_price AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    UNION ALL
    -- Web sales branch
    SELECT
        d.d_year,
        i.i_brand,
        i.i_item_sk,
        d.d_date_sk,
        ws.ws_quantity * ws.ws_sales_price AS sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
),
agg AS (
    SELECT
        d_year,
        i_brand,
        i_item_sk,
        d_date_sk,
        SUM(sales_amount) AS total_sales
    FROM sales_union
    GROUP BY GROUPING SETS (
        (d_year, i_brand, i_item_sk, d_date_sk),
        (d_year, i_brand),
        (d_year),
        (i_brand)
    )
    HAVING SUM(sales_amount) > 1000
),
ranked AS (
    SELECT
        d_year,
        i_brand,
        total_sales,
        i_item_sk,
        d_date_sk,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rn
    FROM agg
    WHERE i_item_sk IS NOT NULL   -- keep rows that can be correlated
)
SELECT
    r.d_year,
    r.i_brand,
    r.total_sales,
    r.rn,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = r.i_item_sk
          AND cr.cr_returned_date_sk = r.d_date_sk
    ) AS total_return_amount
FROM ranked r
WHERE r.rn <= 5
ORDER BY r.d_year, r.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
