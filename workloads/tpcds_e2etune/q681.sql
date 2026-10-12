WITH agg AS (
    SELECT
        s.s_state,
        i.i_category,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year >= 1950
      AND d.d_year = 2002
      AND d.d_quarter_name = 'Q1'
      AND p.p_discount_active = 'Y'
      AND s.s_closed_date_sk IS NULL
    GROUP BY s.s_state, i.i_category
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    s_state,
    i_category,
    unique_customers,
    total_profit,
    avg_discount,
    total_quantity,
    total_profit / NULLIF(unique_customers, 0) AS profit_per_customer,
    RANK() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS profit_rank_by_state
FROM agg
ORDER BY total_profit DESC
