WITH sales AS (
    SELECT ss_customer_sk AS customer_sk,
           ss_cdemo_sk AS cd_demo_sk,
           ss_net_profit AS net_profit,
           ss_sold_date_sk AS sold_date_sk
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_bill_cdemo_sk AS cd_demo_sk,
           ws_net_profit AS net_profit,
           ws_sold_date_sk AS sold_date_sk
    FROM web_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_bill_cdemo_sk AS cd_demo_sk,
           cs_net_profit AS net_profit,
           cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       cd.cd_gender,
       cd.cd_education_status,
       SUM(s.net_profit) AS total_net_profit,
       COUNT(*) AS transaction_count
FROM sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN customer c ON s.customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON s.cd_demo_sk = cd.cd_demo_sk
WHERE d.d_year = 2002
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_education_status
ORDER BY total_net_profit DESC
LIMIT 10
