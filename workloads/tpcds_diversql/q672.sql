WITH sales_by_county AS (
        SELECT ca.ca_address_id,
               ca.ca_county,
               SUM(ss.ss_ext_sales_price) AS total_sales,
               CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
        FROM store_sales ss
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE ca.ca_state = 'TX'               -- example filter on state
          AND ss.ss_ext_sales_price > 0
        GROUP BY ca.ca_address_id, ca.ca_county
    ),
    high_value_sales AS (
        SELECT ca_address_id
        FROM sales_by_county
        WHERE total_sales > 5000
    ),
    low_value_sales AS (
        SELECT ca_address_id
        FROM sales_by_county
        WHERE total_sales <= 5000
    ),
    union_set AS (
        SELECT ca_address_id FROM high_value_sales
        UNION
        SELECT ca_address_id FROM low_value_sales
    ),
    intersect_set AS (
        SELECT ca_address_id FROM high_value_sales
        INTERSECT
        SELECT ca_address_id FROM low_value_sales
    ),
    except_set AS (
        SELECT ca_address_id FROM union_set
        EXCEPT
        SELECT ca_address_id FROM intersect_set
    )
SELECT ca.ca_address_id,
       (SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_addr_sk = ca.ca_address_sk) AS transaction_cnt,
       CASE WHEN (SELECT COALESCE(SUM(ss3.ss_ext_sales_price),0)
                  FROM store_sales ss3
                  WHERE ss3.ss_addr_sk = ca.ca_address_sk) > 20000 THEN 'VIP' ELSE 'Regular' END AS customer_tier
FROM customer_address ca
WHERE ca.ca_address_id IN (SELECT ca_address_id FROM except_set)
ORDER BY transaction_cnt DESC
LIMIT 100
