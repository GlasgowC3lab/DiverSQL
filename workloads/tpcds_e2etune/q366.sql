WITH customer_page_counts AS (
    SELECT wp.wp_customer_sk AS c_customer_sk,
           COUNT(DISTINCT wp.wp_web_page_sk) AS page_visits
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
),
sales_with_returns AS (
    SELECT ss.ss_store_sk,
           ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           ss.ss_net_profit,
           COALESCE(sr.sr_net_loss, 0) AS return_loss,
           ss.ss_quantity,
           COALESCE(sr.sr_return_quantity, 0) AS return_quantity
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
)
SELECT store_name,
       state,
       year_month,
       net_profit_adj,
       return_rate,
       avg_page_visits,
       RANK() OVER (PARTITION BY year_month ORDER BY net_profit_adj DESC) AS profit_rank
FROM (
    SELECT s.s_store_name AS store_name,
           s.s_state AS state,
           date_format(date_parse(cast(sw.ss_sold_date_sk AS varchar), '%Y%m%d'), '%Y-%m') AS year_month,
           SUM(sw.ss_net_profit - sw.return_loss) AS net_profit_adj,
           SUM(sw.return_quantity) * 1.0 / NULLIF(SUM(sw.ss_quantity), 0) AS return_rate,
           AVG(cp.page_visits) AS avg_page_visits
    FROM sales_with_returns sw
    JOIN store s ON sw.ss_store_sk = s.s_store_sk
    JOIN customer c ON sw.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_page_counts cp ON c.c_customer_sk = cp.c_customer_sk
    WHERE s.s_country = 'United States'
      AND c.c_birth_year > 1950
    GROUP BY s.s_store_name,
             s.s_state,
             date_format(date_parse(cast(sw.ss_sold_date_sk AS varchar), '%Y%m%d'), '%Y-%m')
) t
ORDER BY year_month, profit_rank
LIMIT 100
