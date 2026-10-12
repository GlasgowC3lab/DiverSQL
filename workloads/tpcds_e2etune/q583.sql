WITH sales_by_state AS (
    SELECT ca.ca_state,
           SUM(ss.ss_net_paid) AS total_sales_net_paid,
           SUM(ss.ss_net_profit) AS total_sales_net_profit,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk >= 2450000
    GROUP BY ca.ca_state
),
returns_by_state AS (
    SELECT ca.ca_state,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_return_net_loss,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_fee > 20
    GROUP BY ca.ca_state
)
SELECT s.ca_state,
       s.total_sales_net_paid,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit_after_returns,
       CASE WHEN s.total_sales_net_paid > 0
            THEN COALESCE(r.total_return_amount, 0) / s.total_sales_net_paid
            ELSE NULL END AS return_rate,
       RANK() OVER (ORDER BY (s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0)) DESC) AS profit_rank
FROM sales_by_state s
LEFT JOIN returns_by_state r
    ON s.ca_state = r.ca_state
ORDER BY net_profit_after_returns DESC
LIMIT 100
