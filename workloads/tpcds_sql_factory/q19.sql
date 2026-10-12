WITH unified_sales AS (
   SELECT
      ss.ss_sold_date_sk AS sold_date_sk,
      ss.ss_net_profit AS net_profit,
      ss.ss_ext_discount_amt AS discount_amt,
      'store' AS channel,
      ss.ss_cdemo_sk AS cd_demo_sk,
      ss.ss_customer_sk AS customer_sk
   FROM store_sales ss
   UNION ALL
   SELECT
      ws.ws_sold_date_sk AS sold_date_sk,
      ws.ws_net_profit AS net_profit,
      ws.ws_ext_discount_amt AS discount_amt,
      'web' AS channel,
      ws.ws_bill_cdemo_sk AS cd_demo_sk,
      ws.ws_bill_customer_sk AS customer_sk
   FROM web_sales ws
),
sales_with_demo_cust AS (
   SELECT
      us.sold_date_sk,
      us.channel,
      cd.cd_gender,
      us.net_profit,
      us.discount_amt,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name
   FROM unified_sales us
   JOIN customer_demographics cd ON us.cd_demo_sk = cd.cd_demo_sk
   JOIN customer c ON us.customer_sk = c.c_customer_sk
)
SELECT
   swdc.sold_date_sk,
   swdc.channel,
   swdc.cd_gender,
   COUNT(*) AS sales_cnt,
   SUM(swdc.net_profit) AS total_net_profit,
   AVG(swdc.discount_amt) AS avg_discount,
   DENSE_RANK() OVER (PARTITION BY swdc.channel ORDER BY SUM(swdc.net_profit) DESC) AS profit_rank,
   CASE 
      WHEN AVG(swdc.discount_amt) > 50 THEN 'HighDiscount'
      WHEN AVG(swdc.discount_amt) BETWEEN 20 AND 50 THEN 'MediumDiscount'
      ELSE 'LowDiscount'
   END AS discount_level,
   MIN(swdc.c_customer_id) AS example_customer_id,
   MIN(swdc.c_first_name) AS example_first_name,
   MIN(swdc.c_last_name) AS example_last_name
FROM sales_with_demo_cust swdc
GROUP BY swdc.sold_date_sk, swdc.channel, swdc.cd_gender
ORDER BY swdc.sold_date_sk, swdc.channel, swdc.cd_gender
