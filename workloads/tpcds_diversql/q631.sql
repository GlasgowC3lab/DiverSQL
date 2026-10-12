WITH
    /* Sample a subset of customer addresses and apply string filters */
    filtered_customers AS (
        SELECT
            ca_address_sk,
            ca_state,
            ca_city,
            ca_street_number,
            ca_street_name,
            CONCAT(ca_street_number, ' ', ca_street_name) AS full_street,
            REGEXP_EXTRACT(ca_street_name, '([A-Za-z]+)', 1) AS first_word
        FROM customer_address
        TABLESAMPLE BERNOULLI (10)
        WHERE ca_street_name LIKE '%Washington%'
          AND REGEXP_LIKE(ca_city, '^S')
          AND EXISTS (
              SELECT 1 FROM store s WHERE s.s_state = ca_state
          )
    ),
    /* Aggregate net profit per store for fiscal year 1908 (current quarter) */
    store_profit AS (
        SELECT
            s.s_store_id,
            s.s_state,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(*) AS txn_count
        FROM store_sales ss
        JOIN filtered_customers fc ON ss.ss_addr_sk = fc.ca_address_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE d.d_fy_year = 1908
          AND d.d_current_quarter = 'Y'
        GROUP BY s.s_store_id, s.s_state
    ),
    /* Items sold in catalog with a price higher than the overall catalog average */
    high_price_items AS (
        SELECT cs.cs_item_sk AS item_sk
        FROM catalog_sales cs
        WHERE cs.cs_sales_price > (
            SELECT AVG(cs2.cs_sales_price)
            FROM catalog_sales cs2
        )
    ),
    /* Items appearing in web sales */
    web_items AS (
        SELECT ws.ws_item_sk AS item_sk
        FROM web_sales ws
        WHERE ws.ws_quantity > 0
    ),
    /* Items sold both in catalog (high price) and web channels */
    common_items AS (
        SELECT hp.item_sk
        FROM high_price_items hp
        INTERSECT
        SELECT wi.item_sk
        FROM web_items wi
    ),
    /* Items sold in catalog that were never returned */
    non_returned_items AS (
        SELECT cs.cs_item_sk AS item_sk
        FROM catalog_sales cs
        EXCEPT
        SELECT cr.cr_item_sk
        FROM catalog_returns cr
    )
SELECT
    sp.s_store_id,
    sp.s_state,
    sp.total_net_profit,
    sp.txn_count,
    (SELECT COUNT(DISTINCT ci.item_sk) FROM common_items ci) AS common_item_count,
    (SELECT COUNT(DISTINCT nri.item_sk) FROM non_returned_items nri) AS non_returned_item_count
FROM store_profit sp
ORDER BY sp.total_net_profit DESC
LIMIT 100
