WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_product_name,
        CAST(cs.cs_order_number AS VARCHAR) AS order_number_str,
        concat(i.i_item_id, '_', CAST(cs.cs_order_number AS VARCHAR)) AS item_order_key
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 0
),
words AS (
    SELECT
        s.*,
        lower(regexp_replace(s.i_item_desc, '[^A-Za-z0-9 ]', '')) AS cleaned_desc
    FROM sales_data s
),
exploded AS (
    SELECT
        s.item_order_key,
        s.i_item_id,
        s.i_product_name,
        s.cs_ext_sales_price,
        s.cs_bill_customer_sk,
        word
    FROM words s
    CROSS JOIN UNNEST(split(s.cleaned_desc, ' ')) AS t(word)
    WHERE word <> ''
),
aggregated AS (
    SELECT
        word,
        count(*) AS occurrence_count,
        sum(cs_ext_sales_price) AS total_sales,
        count(DISTINCT cs_bill_customer_sk) AS distinct_customers,
        avg(length(word)) AS avg_word_length,
        CASE
            WHEN length(word) <= 3 THEN 'short'
            WHEN length(word) BETWEEN 4 AND 7 THEN 'medium'
            ELSE 'long'
        END AS length_category,
        min(item_order_key) AS example_item_order_key
    FROM exploded
    GROUP BY word
)
SELECT
    word,
    occurrence_count,
    total_sales,
    distinct_customers,
    round(avg_word_length, 2) AS avg_word_len,
    length_category,
    example_item_order_key
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
