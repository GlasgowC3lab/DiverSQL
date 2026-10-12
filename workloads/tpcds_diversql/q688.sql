WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ca.ca_city,
        ca.ca_state,
        s.s_market_desc,
        s.s_city,
        s.s_state
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_ext_sales_price > 500
      AND ss.ss_quantity >= 2
      AND ca.ca_state = 'CA'
      AND s.s_market_desc LIKE '%Financial%'
      AND s.s_gmt_offset >= -5.00
      AND ss.ss_net_profit > 0
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_addr_sk = ss.ss_addr_sk
            AND ss2.ss_ext_discount_amt > 10
      )
),
aggregated AS (
    SELECT
        ca_city,
        ca_state,
        s_market_desc,
        s_city,
        s_state,
        store_sk,
        COUNT(*) AS sales_cnt,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        MIN(ss_ext_sales_price) AS min_sale,
        MAX(ss_ext_sales_price) AS max_sale,
        (SELECT SUM(ss3.ss_ext_sales_price)
         FROM store_sales ss3
         WHERE ss3.ss_store_sk = fs.store_sk) AS store_total_sales
    FROM filtered_sales fs
    GROUP BY CUBE (ca_city, ca_state, s_market_desc, s_city, s_state, store_sk)
    HAVING COUNT(*) > 3
)
SELECT
    ca_city,
    ca_state,
    s_market_desc,
    s_city,
    s_state,
    store_sk,
    total_sales,
    store_total_sales
FROM aggregated
WHERE total_sales >= 1000
EXCEPT
SELECT
    ca_city,
    ca_state,
    s_market_desc,
    s_city,
    s_state,
    store_sk,
    total_sales,
    store_total_sales
FROM aggregated
WHERE total_sales < 1500
LIMIT 100
