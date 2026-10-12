WITH store_metrics AS (
    SELECT
        s.s_state,
        s.s_city,
        s.s_store_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        ROUND(SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0), 4) AS profit_margin,
        AVG(ss.ss_ext_tax) AS avg_tax
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
      AND ss.ss_quantity > 0
    GROUP BY s.s_state, s.s_city, s.s_store_name
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    s_state,
    s_city,
    s_store_name,
    total_sales,
    total_profit,
    profit_margin,
    avg_tax,
    RANK() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS state_profit_rank
FROM store_metrics
ORDER BY total_profit DESC
LIMIT 100
