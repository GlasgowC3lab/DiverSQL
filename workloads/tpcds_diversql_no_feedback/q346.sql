WITH filtered_sales AS (
    SELECT
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_addr_sk,
        ss.ss_coupon_amt
    FROM store_sales ss
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_sales s2
        WHERE s2.ss_addr_sk = ss.ss_addr_sk
          AND s2.ss_coupon_amt > 500
    )
)
SELECT
    concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
    ca.ca_country,
    sum(fs.ss_ext_sales_price) AS total_sales,
    avg(fs.ss_ext_discount_amt) AS avg_discount,
    count(*) AS transaction_count,
    regexp_extract(ca.ca_address_id, '(AAAAAAA.)', 1) AS address_prefix
FROM filtered_sales fs
JOIN customer_address ca
  ON fs.ss_addr_sk = ca.ca_address_sk
WHERE regexp_like(ca.ca_address_id, '^AAAAAAA[AE]A')
  AND ca.ca_zip LIKE '57%'
GROUP BY
    concat(ca.ca_city, ', ', ca.ca_state),
    ca.ca_country,
    regexp_extract(ca.ca_address_id, '(AAAAAAA.)', 1)
ORDER BY total_sales DESC
LIMIT 100
