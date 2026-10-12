WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS cust_sk,
           ss.ss_store_sk AS store_sk,
           CAST(NULL AS integer) AS catalog_page_sk,
           CAST(NULL AS integer) AS web_page_sk,
           ss.ss_net_profit AS net_profit,
           ss.ss_net_paid AS net_paid
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS cust_sk,
           CAST(NULL AS integer) AS store_sk,
           cs.cs_catalog_page_sk AS catalog_page_sk,
           CAST(NULL AS integer) AS web_page_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_bill_customer_sk AS cust_sk,
           CAST(NULL AS integer) AS store_sk,
           CAST(NULL AS integer) AS catalog_page_sk,
           ws.ws_web_page_sk AS web_page_sk,
           ws.ws_net_profit AS net_profit,
           ws.ws_net_paid AS net_paid
    FROM web_sales ws
),
agg_sales AS (
    SELECT d.d_year,
           s.s_state,
           i.i_brand,
           SUM(us.net_profit) AS total_profit,
           COUNT(*) AS total_transactions
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    JOIN customer c ON us.cust_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, s.s_state, i.i_brand
)
SELECT a.d_year,
       a.s_state,
       a.i_brand,
       a.total_profit,
       a.total_transactions,
       RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
FROM agg_sales a
ORDER BY a.d_year, a.total_profit DESC
LIMIT 100
