WITH sales AS (
    SELECT ca.ca_county,
           ca.ca_street_type,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -6.00
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451500
    GROUP BY ca.ca_county, ca.ca_street_type
),
returns AS (
    SELECT ca.ca_county,
           ca.ca_street_type,
           SUM(wr.wr_return_amt_inc_tax) AS total_returns,
           SUM(wr.wr_net_loss) AS total_return_loss,
           COUNT(DISTINCT wr.wr_order_number) AS num_returns
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -6.00
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2451500
    GROUP BY ca.ca_county, ca.ca_street_type
)
SELECT
    s.ca_county AS county,
    s.ca_street_type AS street_type,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    s.num_transactions,
    COALESCE(r.num_returns, 0) AS num_returns,
    RANK() OVER (ORDER BY (s.total_sales - COALESCE(r.total_returns, 0)) DESC) AS sales_rank
FROM sales s
LEFT JOIN returns r
  ON s.ca_county = r.ca_county
 AND s.ca_street_type = r.ca_street_type
ORDER BY net_profit DESC
LIMIT 100
