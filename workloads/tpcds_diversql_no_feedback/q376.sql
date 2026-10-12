WITH filtered_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_product_name, '(?i)metal')
      AND c.c_email_address LIKE '%@example.com'
      AND p.p_discount_active = 'Y'
    GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
),
ranked_sales AS (
    SELECT
        fs.cs_bill_customer_sk,
        fs.cs_item_sk,
        fs.total_sales,
        fs.sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY fs.cs_bill_customer_sk ORDER BY fs.total_sales DESC) AS rnk
    FROM filtered_sales fs
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = fs.cs_bill_customer_sk
          AND ws.ws_item_sk = fs.cs_item_sk
    )
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    i.i_item_id,
    i.i_product_name,
    REGEXP_EXTRACT(i.i_product_name, '(\\w+)', 1) AS product_first_word,
    SUBSTRING(i.i_product_name FROM 1 FOR 10) AS product_prefix,
    rs.total_sales,
    rs.sales_cnt,
    rs.rnk
FROM ranked_sales rs
JOIN customer c ON rs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i ON rs.cs_item_sk = i.i_item_sk
WHERE rs.rnk <= 5
ORDER BY rs.total_sales DESC
LIMIT 100
