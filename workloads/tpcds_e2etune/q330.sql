SELECT i.i_category,
       i.i_brand,
       SUM(ss.ss_net_profit) AS total_profit,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(ss.ss_ext_discount_amt) AS total_discount,
       AVG(ss.ss_sales_price) AS avg_sales_price,
       (SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_net_paid), 0)) AS profit_margin
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year >= 1970
  AND cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453000
GROUP BY i.i_category, i.i_brand
HAVING SUM(ss.ss_net_profit) > 500
ORDER BY profit_margin DESC
LIMIT 10
