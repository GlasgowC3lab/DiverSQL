WITH
sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        i.i_product_name AS product_name,
        i.i_brand AS brand,
        i.i_category AS category,
        i.i_color AS color,
        cc.cc_name AS location_name,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        d.d_date AS sold_date,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_ticket_number AS order_number,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        i.i_product_name AS product_name,
        i.i_brand AS brand,
        i.i_category AS category,
        i.i_color AS color,
        s.s_store_name AS location_name,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        d.d_date AS sold_date,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        i.i_product_name AS product_name,
        i.i_brand AS brand,
        i.i_category AS category,
        i.i_color AS color,
        NULL AS location_name,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        d.d_date AS sold_date,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
string_metrics AS (
    SELECT
        sales_channel,
        order_number,
        concat_ws('|',
            lower(sales_channel),
            replace(coalesce(location_name, ''), ' ', ''),
            substr(product_name, 1, 10),
            lower(concat(first_name, last_name)),
            format_datetime(CAST(sold_date AS timestamp), 'yyyyMMdd')
        ) AS composite_str,
        length(concat_ws('|', coalesce(location_name, ''), product_name, first_name, last_name)) AS total_len,
        length(regexp_replace(lower(product_name), '[^aeiou]', '')) AS vowel_count,
        regexp_like(product_name, '(?i)(Pro|Premium)') AS has_pro,
        cardinality(split(product_name, '\\s+')) AS word_count,
        regexp_extract(product_name, '(\\b\\w{3}\\b)') AS three_letter_word,
        regexp_replace(product_name, '[^A-Za-z0-9]', '') AS alphanumeric_name,
        array_join(split(product_name, '\\s+'), '|') AS words_joined,
        row_number() OVER (
            PARTITION BY sales_channel
            ORDER BY length(concat_ws('|', coalesce(location_name, ''), product_name, first_name, last_name)) DESC
        ) AS rn
    FROM sales_union
)
SELECT
    sales_channel,
    count(*) AS total_orders,
    avg(total_len) AS avg_total_len,
    avg(vowel_count) AS avg_vowel_count,
    sum(CASE WHEN has_pro THEN 1 ELSE 0 END) AS pro_product_orders,
    avg(word_count) AS avg_word_count,
    count(DISTINCT three_letter_word) AS distinct_three_letter_words,
    max(rn) AS max_rn
FROM string_metrics
WHERE rn <= 10
GROUP BY sales_channel
ORDER BY sales_channel
