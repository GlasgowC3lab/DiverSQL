WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
        COUNT(*) AS total_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Women'
      AND p.p_channel_tv = 'Y'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    total_net_profit,
    total_net_paid,
    avg_discount,
    distinct_items_sold,
    total_transactions,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, d_month_seq, profit_rank
