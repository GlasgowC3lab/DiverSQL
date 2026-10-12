WITH sales_by_store_date AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(*) AS txn_count
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
top_items AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS date_sk,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_quantity) AS qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, i.i_item_sk, i.i_product_name
),
ranked_items AS (
    SELECT
        store_sk,
        date_sk,
        i_item_sk,
        i_product_name,
        qty,
        ROW_NUMBER() OVER (PARTITION BY store_sk, date_sk ORDER BY qty DESC) AS rn
    FROM top_items
),
top_n_items AS (
    SELECT
        store_sk,
        date_sk,
        array_agg(
            concat(
                regexp_replace(lower(i_product_name), '\\s+', '_'),
                ':',
                CAST(qty AS VARCHAR)
            )
            ORDER BY qty DESC
        ) AS items_arr
    FROM ranked_items
    WHERE rn <= 5
    GROUP BY store_sk, date_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    CAST(sales.total_sales AS VARCHAR) AS total_sales_str,
    CAST(sales.txn_count AS VARCHAR) AS txn_count_str,
    length(concat(s.s_store_name, ':', CAST(d.d_year AS VARCHAR))) AS name_year_len,
    regexp_replace(concat_ws('|', tn.items_arr), '_[0-9]+', '') AS items_concat_cleaned,
    array_join(
        transform(tn.items_arr, x -> upper(regexp_extract(x, '([^:]+)', 1))),
        ', '
    ) AS top_items_upper
FROM sales_by_store_date sales
JOIN top_n_items tn
    ON sales.store_sk = tn.store_sk AND sales.date_sk = tn.date_sk
JOIN store s
    ON sales.store_sk = s.s_store_sk
JOIN date_dim d
    ON sales.date_sk = d.d_date_sk
WHERE d.d_year = 2001
ORDER BY s.s_store_name, d.d_month_seq
LIMIT 100
