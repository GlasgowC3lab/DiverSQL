WITH agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, ca.ca_state, i.i_category
)
SELECT
    d_year,
    ca_state,
    i_category,
    total_net_profit,
    total_net_paid_inc_tax,
    total_quantity,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
