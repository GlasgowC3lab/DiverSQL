WITH store_monthly_profit AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    s_store_id,
    d_year,
    d_month_seq,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
FROM store_monthly_profit
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 10
