WITH sampled_inventory AS (
        SELECT inv_item_sk
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    promo_items AS (
        SELECT DISTINCT p_item_sk
        FROM promotion
        WHERE regexp_like(p_promo_name, '(?i)discount')
    ),
    promo_not_in_inventory AS (
        SELECT p_item_sk
        FROM promo_items
        EXCEPT
        SELECT inv_item_sk
        FROM sampled_inventory
    ),
    joined_data AS (
        SELECT
            i.i_item_sk,
            i.i_category AS category,
            i.i_item_desc,
            sr.sr_return_amt,
            sr.sr_return_quantity,
            CASE
                WHEN i.i_current_price > 100 THEN 'expensive'
                WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'midrange'
                ELSE 'budget'
            END AS price_segment,
            substring(i.i_brand FROM 1 FOR 3) AS brand_prefix,
            regexp_extract(i.i_item_desc, '(\\d+)', 1) AS numeric_code
        FROM store_returns sr
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        JOIN promo_not_in_inventory pni
            ON i.i_item_sk = pni.p_item_sk
        WHERE i.i_item_desc LIKE '%steel%'
    )
SELECT
    category,
    price_segment,
    COUNT(*) AS returns_cnt,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT i_item_sk) AS distinct_items,
    MAX(CAST(numeric_code AS integer)) AS max_numeric_code
FROM joined_data
GROUP BY category, price_segment
ORDER BY total_return_amount DESC
LIMIT 100
