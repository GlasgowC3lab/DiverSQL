WITH sampled_site AS (
    SELECT *
    FROM web_site TABLESAMPLE BERNOULLI (10)
),
filtered_sales AS (
    SELECT ws.*
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
      AND ws.ws_ext_sales_price > (
          SELECT MAX(ws2.ws_ext_sales_price)
          FROM web_sales ws2
          WHERE ws2.ws_quantity > 0
      ) * 0.5
      AND ws.ws_quantity >= 1
)
SELECT
    ss.web_name,
    cd.cd_gender,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_ext_discount_amt) AS avg_discount,
    MIN(fs.ws_ext_sales_price) AS min_sales_price,
    MAX(fs.ws_ext_sales_price) AS max_sales_price
FROM filtered_sales fs
RIGHT JOIN sampled_site ss
    ON fs.ws_web_site_sk = ss.web_site_sk
JOIN customer c
    ON fs.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ss.web_county IN ('Mesa County', 'Bronx County')
  AND cd.cd_education_status = 'College'
  AND ca.ca_state = 'CA'
  AND c.c_customer_sk NOT IN (
        SELECT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_ext_sales_price > 10000
    )
GROUP BY ss.web_name, cd.cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
