WITH cust_sales AS (
    SELECT
        cs_bill_customer_sk AS cust_sk,
        COUNT(*) AS num_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_net_paid_inc_ship_tax) AS total_paid,
        AVG(cs_ext_discount_amt) AS avg_discount,
        SUM(cs_net_profit) / NULLIF(SUM(cs_net_paid_inc_ship_tax), 0) AS profit_margin
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450820 AND 2450826
      AND cs_net_paid_inc_ship_tax > 1000
    GROUP BY cs_bill_customer_sk
    HAVING COUNT(*) > 5
)
SELECT
    c.c_customer_id,
    c.c_birth_country,
    cs.num_sales,
    cs.total_profit,
    cs.total_paid,
    cs.avg_discount,
    cs.profit_margin,
    RANK() OVER (PARTITION BY c.c_birth_country ORDER BY cs.total_profit DESC) AS profit_rank_in_country
FROM cust_sales cs
JOIN customer c
    ON cs.cust_sk = c.c_customer_sk
WHERE c.c_birth_country IS NOT NULL
ORDER BY cs.total_profit DESC
LIMIT 10
