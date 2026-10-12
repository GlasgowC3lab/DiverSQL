WITH store_daily AS (
    SELECT ss_sold_date_sk AS date_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(DISTINCT ss_customer_sk) AS store_customer_cnt,
           AVG(ss_sales_price) AS avg_store_price
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_sold_date_sk
),
web_daily AS (
    SELECT ws_sold_date_sk AS date_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(DISTINCT ws_bill_customer_sk) AS web_customer_cnt,
           AVG(ws_sales_price) AS avg_web_price
    FROM web_sales
    WHERE ws_quantity BETWEEN 2 AND 10
    GROUP BY ws_sold_date_sk
),
combined AS (
    SELECT COALESCE(s.date_sk, w.date_sk) AS date_sk,
           COALESCE(s.store_net_profit, 0) AS store_net_profit,
           COALESCE(w.web_net_profit, 0) AS web_net_profit,
           COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS total_customer_cnt,
           COALESCE(s.avg_store_price, 0) AS avg_store_price,
           COALESCE(w.avg_web_price, 0) AS avg_web_price
    FROM store_daily s
    FULL JOIN web_daily w ON s.date_sk = w.date_sk
)
SELECT date_sk,
       store_net_profit,
       web_net_profit,
       total_customer_cnt,
       (store_net_profit + web_net_profit) AS total_net_profit,
       (avg_store_price + avg_web_price) / 2 AS overall_avg_price,
       ROW_NUMBER() OVER (ORDER BY (store_net_profit + web_net_profit) DESC) AS profit_row_num,
       (SELECT COUNT(*) FROM promotion p WHERE date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS active_promos
FROM combined
WHERE date_sk >= 2450000
ORDER BY date_sk DESC
LIMIT 150
