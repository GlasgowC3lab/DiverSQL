WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),

joined_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_tax_percentage,
        ca.ca_state AS customer_state,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cc.cc_name,
        ws.ws_net_paid,
        wp.wp_type,
        ss.ss_ext_sales_price,
        CASE 
            WHEN ss.ss_net_profit > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS sales_category
    FROM sampled_store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_tax_percentage >= 0.03
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
      AND cs.cs_ext_sales_price > 5000
      AND wp.wp_type IN ('Home', 'Category')
      AND ss.ss_wholesale_cost < 50
),

agg1 AS (
    SELECT
        s_store_id,
        sales_category,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(cs_net_paid) AS avg_catalog_paid,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY s_store_id, sales_category
    HAVING COUNT(*) > 5
),

filtered_keys AS (
    SELECT s_store_id FROM agg1 WHERE total_sales > 10000
),

intersect_keys AS (
    SELECT s_store_id FROM agg1 WHERE avg_catalog_paid > 2000
    INTERSECT
    SELECT s_store_id FROM agg1 WHERE txn_count < 20
)

SELECT
    a.s_store_id,
    a.sales_category,
    a.total_sales,
    a.avg_catalog_paid,
    a.txn_count,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_store_sk = s.s_store_sk) AS total_store_txns
FROM agg1 a
JOIN store s ON a.s_store_id = s.s_store_id
WHERE a.s_store_id IN (SELECT s_store_id FROM filtered_keys)
  AND a.s_store_id IN (SELECT s_store_id FROM intersect_keys)
ORDER BY a.total_sales DESC
LIMIT 100
