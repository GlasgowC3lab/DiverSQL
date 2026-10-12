WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        i.i_class,
        p.p_promo_name,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND s.s_state = 'CA'
)
SELECT
    d_year,
    s_state,
    i_category,
    i_class,
    p_promo_name,
    total_net_paid,
    total_net_profit,
    total_quantity,
    num_orders,
    SUM(total_net_paid) OVER (PARTITION BY i_category ORDER BY d_year) AS cumulative_sales_by_category
FROM (
    SELECT
        d_year,
        s_state,
        i_category,
        i_class,
        p_promo_name,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS num_orders
    FROM sales_agg
    GROUP BY d_year, s_state, i_category, i_class, p_promo_name
) AS agg
ORDER BY total_net_paid DESC
LIMIT 100
