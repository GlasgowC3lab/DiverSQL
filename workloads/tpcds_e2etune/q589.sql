WITH store_profit AS (
    SELECT
        ss.ss_store_sk,
        s.s_state,
        s.s_city,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND t.t_shift = 'Evening'
      AND t.t_hour BETWEEN 18 AND 23
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY ss.ss_store_sk, s.s_state, s.s_city
), ranked_stores AS (
    SELECT
        sp.*,
        ROW_NUMBER() OVER (PARTITION BY sp.s_state ORDER BY sp.total_net_profit DESC) AS state_rank
    FROM store_profit sp
)
SELECT
    rs.s_state,
    rs.s_city,
    rs.total_net_profit,
    rs.avg_discount,
    rs.distinct_customers,
    rs.total_quantity,
    rs.state_rank
FROM ranked_stores rs
WHERE rs.state_rank <= 5
ORDER BY rs.s_state, rs.state_rank
