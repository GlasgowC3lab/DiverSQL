WITH sales_agg AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_quantity) AS total_quantity,
           COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cs.cs_bill_customer_sk
),
returns_agg AS (
    SELECT wr.wr_refunded_customer_sk AS cust_sk,
           SUM(wr.wr_net_loss) AS total_return_loss,
           COUNT(*) AS return_count
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT c.c_customer_id,
       ca.ca_country,
       ca.ca_city,
       COALESCE(s.total_net_profit, 0) AS total_net_profit,
       COALESCE(s.total_quantity, 0) AS total_quantity,
       COALESCE(s.distinct_pages, 0) AS distinct_pages,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       COALESCE(r.return_count, 0) AS return_count,
       (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_contribution,
       RANK() OVER (ORDER BY (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_agg s ON c.c_customer_sk = s.cust_sk
LEFT JOIN returns_agg r ON c.c_customer_sk = r.cust_sk
WHERE (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0)) > 0
ORDER BY net_contribution DESC
LIMIT 100
