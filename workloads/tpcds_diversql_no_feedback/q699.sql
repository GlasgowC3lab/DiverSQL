WITH sales_with_address AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_net_profit,
        cs.cs_list_price,
        cs.cs_quantity,
        ca.ca_address_id,
        ca.ca_location_type,
        ca.ca_city,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_location_type LIKE '%apartment%'
      AND regexp_like(ca.ca_address_id, '^A{8}A')
      AND cs.cs_list_price > 120
)
SELECT
    cp.cp_department,
    cp.cp_type,
    COUNT(DISTINCT swa.cs_order_number) AS orders,
    SUM(swa.cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(swa.cs_net_profit) > 0 THEN 'Positive'
        ELSE 'Non-Positive'
    END AS profit_category,
    CONCAT('Dept-', cp.cp_department) AS dept_label,
    MIN(REGEXP_EXTRACT(swa.ca_address_id, '(A{5})([A-Z]+)', 2)) AS addr_suffix
FROM sales_with_address swa
JOIN catalog_page cp
    ON swa.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type LIKE 'qu%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_hdemo_sk = swa.hd_demo_sk
          AND sr.sr_return_amt > 0
    )
GROUP BY cp.cp_department, cp.cp_type
ORDER BY total_profit DESC
LIMIT 100
