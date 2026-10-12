WITH page_item_sales AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS sales,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS qty
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number IN (1, 3, 5)
      AND cp.cp_end_date_sk BETWEEN 2450905 AND 2451087
    GROUP BY cs.cs_catalog_page_sk, cs.cs_item_sk
    HAVING SUM(cs.cs_ext_sales_price) > 5000
)
SELECT
    cp.cp_catalog_page_number,
    i.i_category,
    SUM(pis.sales) AS total_sales,
    SUM(pis.profit) AS total_profit,
    AVG(pis.sales) AS avg_sales_per_item,
    SUM(pis.qty) AS total_quantity,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items
FROM page_item_sales pis
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = pis.cs_catalog_page_sk
   AND cs.cs_item_sk = pis.cs_item_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = pis.cs_catalog_page_sk
JOIN item i
    ON i.i_item_sk = pis.cs_item_sk
WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
  AND cs.cs_ext_discount_amt > 0
GROUP BY cp.cp_catalog_page_number, i.i_category
ORDER BY total_sales DESC
LIMIT 100
