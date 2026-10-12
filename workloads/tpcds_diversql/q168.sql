WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_date,
        ss.ss_store_sk,
        s.s_store_name,
        s.s_city,
        ss.ss_item_sk,
        i.i_item_desc,
        i.i_color,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND s.s_store_name LIKE '%Market%'
)
SELECT
    d.d_date,
    s.s_store_name,
    concat(s.s_city, '-', i.i_color) AS city_color,
    regexp_extract(i.i_item_desc, '(\\d+)', 1) AS item_code,
    sum(ss.ss_ext_sales_price) AS total_sales,
    count(DISTINCT ss.ss_ticket_number) AS num_transactions
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE regexp_like(i.i_item_desc, '\\d{3}')
  AND s.s_store_name LIKE '%Market%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_store_sk = ss.ss_store_sk
    )
GROUP BY d.d_date, s.s_store_name, s.s_city, i.i_color, regexp_extract(i.i_item_desc, '(\\d+)', 1)
ORDER BY total_sales DESC
LIMIT 100
