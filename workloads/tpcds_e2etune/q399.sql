WITH monthly_store_metrics AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state IN ('AZ', 'NM', 'CO')
      AND d.d_year = 2022
      AND s.s_closed_date_sk IS NULL
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    s_store_id,
    d_year,
    d_month_seq,
    total_profit,
    total_sales,
    avg_discount,
    distinct_customers,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
FROM monthly_store_metrics
ORDER BY d_year, d_month_seq, total_profit DESC
