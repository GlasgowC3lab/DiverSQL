WITH sales_by_country AS (
    SELECT
        ca.ca_country AS country,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 5000
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND cs.cs_ext_list_price > 1000
    GROUP BY ca.ca_country
),
returns_by_country AS (
    SELECT
        ca.ca_country AS country,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2450825
      AND wp.wp_type = 'product'
    GROUP BY ca.ca_country
)
SELECT
    s.country,
    s.total_net_profit,
    s.total_discount,
    s.distinct_orders,
    s.total_quantity,
    s.avg_discount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.return_count, 0) AS return_count,
    CASE WHEN s.total_net_profit = 0 THEN NULL
         ELSE (COALESCE(r.total_return_amount, 0) / s.total_net_profit) END AS return_to_sales_ratio,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_by_country s
LEFT JOIN returns_by_country r
    ON s.country = r.country
ORDER BY s.total_net_profit DESC
LIMIT 200
