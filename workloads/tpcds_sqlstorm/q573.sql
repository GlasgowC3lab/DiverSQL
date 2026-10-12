WITH sales AS (
    SELECT d.d_year,
           s.s_state AS state,
           ss.ss_net_profit AS net_profit,
           ss.ss_net_paid AS net_paid,
           ss.ss_quantity AS quantity,
           ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           cc.cc_state AS state,
           cs.cs_net_profit AS net_profit,
           cs.cs_net_paid AS net_paid,
           cs.cs_quantity AS quantity,
           cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           w.web_state AS state,
           ws.ws_net_profit AS net_profit,
           ws.ws_net_paid AS net_paid,
           ws.ws_quantity AS quantity,
           ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT state,
       d_year,
       SUM(net_profit) AS total_profit,
       SUM(net_paid) AS total_paid,
       SUM(quantity) AS total_quantity,
       COUNT(DISTINCT customer_sk) AS distinct_customers
FROM sales
WHERE d_year BETWEEN 1999 AND 2002
GROUP BY state, d_year
ORDER BY total_profit DESC
LIMIT 200
