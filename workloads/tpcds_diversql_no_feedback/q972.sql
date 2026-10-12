WITH sales AS (
    SELECT
        'store_sales' AS src,
        i.i_item_id,
        i.i_item_desc,
        ss.ss_ext_sales_price AS total_sales,
        ARRAY[ss.ss_quantity, ss.ss_coupon_amt] AS qty_coupon_arr
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
      AND ss.ss_ext_sales_price > 1000
),
sales_unnest AS (
    SELECT
        src,
        i_item_id,
        i_item_desc,
        total_sales,
        CAST(NULL AS decimal(7,2)) AS total_return,
        val AS value
    FROM sales
    CROSS JOIN UNNEST(qty_coupon_arr) AS t(val)
),
returns AS (
    SELECT
        'web_returns' AS src,
        i.i_item_id,
        i.i_item_desc,
        wr.wr_return_amt AS total_return,
        ARRAY[wr.wr_return_quantity, wr.wr_return_amt] AS qty_return_arr
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 500
),
returns_unnest AS (
    SELECT
        src,
        i_item_id,
        i_item_desc,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        total_return,
        val AS value
    FROM returns
    CROSS JOIN UNNEST(qty_return_arr) AS t(val)
)
SELECT src,
       i_item_id,
       i_item_desc,
       total_sales,
       total_return,
       value
FROM sales_unnest
UNION ALL
SELECT src,
       i_item_id,
       i_item_desc,
       total_sales,
       total_return,
       value
FROM returns_unnest
LIMIT 100
