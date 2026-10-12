SELECT *
FROM (
  SELECT d_year,
         c_customer_id,
         c_first_name,
         c_last_name,
         total_profit,
         RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
  FROM (
    SELECT d.d_year AS d_year,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           SUM(sale.net_profit) AS total_profit
    FROM (
      SELECT cs.cs_sold_date_sk AS sold_date_sk,
             cs.cs_bill_customer_sk AS customer_sk,
             cs.cs_net_profit AS net_profit
      FROM catalog_sales cs
      UNION ALL
      SELECT ss.ss_sold_date_sk AS sold_date_sk,
             ss.ss_customer_sk AS customer_sk,
             ss.ss_net_profit AS net_profit
      FROM store_sales ss
      UNION ALL
      SELECT ws.ws_sold_date_sk AS sold_date_sk,
             ws.ws_bill_customer_sk AS customer_sk,
             ws.ws_net_profit AS net_profit
      FROM web_sales ws
    ) sale
    JOIN date_dim d ON sale.sold_date_sk = d.d_date_sk
    JOIN customer c ON sale.customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, c.c_customer_id, c.c_first_name, c.c_last_name
  ) grouped
) ranked
WHERE profit_rank <= 100
ORDER BY d_year, profit_rank
