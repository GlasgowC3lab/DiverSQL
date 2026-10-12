WITH filtered_orders AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_tax AS ext_tax,
        cc.cc_name AS cc_name,
        cp.cp_type AS cp_type,
        cp.cp_description AS cp_description,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        REGEXP_EXTRACT(cp.cp_description, '(\\d{3})') AS extracted_code
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE c.c_last_name LIKE 'N%'
      AND REGEXP_LIKE(cp.cp_description, '\\d{3}')
      AND cs.cs_ext_tax > (
          SELECT AVG(p_cost)
          FROM promotion
          WHERE p_discount_active = 'Y'
      )
)
SELECT
    cc_name,
    cp_type,
    extracted_code,
    COUNT(DISTINCT order_number) AS order_cnt,
    SUM(net_profit) AS total_profit,
    MIN(CONCAT(c_first_name, ' ', c_last_name)) AS example_full_name
FROM filtered_orders
WHERE order_number NOT IN (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 10
)
GROUP BY cc_name, cp_type, extracted_code
ORDER BY total_profit DESC
LIMIT 100
