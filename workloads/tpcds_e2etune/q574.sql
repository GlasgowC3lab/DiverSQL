WITH sales_returns AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
           AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year BETWEEN 2022 AND 2023
      AND (p.p_channel_email = 'Y' OR p.p_promo_sk IS NULL)
    GROUP BY
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit
),
profit_by_category AS (
    SELECT
        sr.ss_store_sk,
        sr.s_store_name,
        sr.d_year,
        sr.d_month_seq,
        sr.i_category,
        SUM(sr.ss_net_profit - sr.total_return_loss) AS net_profit_adj,
        SUM(sr.ss_quantity) AS total_quantity
    FROM sales_returns sr
    GROUP BY
        sr.ss_store_sk,
        sr.s_store_name,
        sr.d_year,
        sr.d_month_seq,
        sr.i_category
),
store_month_totals AS (
    SELECT
        pbc.ss_store_sk,
        pbc.d_year,
        pbc.d_month_seq,
        SUM(pbc.net_profit_adj) AS total_store_profit
    FROM profit_by_category pbc
    GROUP BY
        pbc.ss_store_sk,
        pbc.d_year,
        pbc.d_month_seq
)
SELECT
    sub.store_sk,
    sub.store_name,
    sub.d_year,
    sub.d_month_seq,
    sub.i_category,
    sub.net_profit_adj,
    sub.total_quantity,
    sub.profit_share_pct,
    sub.category_rank,
    sub.prev_month_profit,
    sub.mom_profit_growth
FROM (
    SELECT
        pb.ss_store_sk AS store_sk,
        pb.s_store_name AS store_name,
        pb.d_year,
        pb.d_month_seq,
        pb.i_category,
        pb.net_profit_adj,
        pb.total_quantity,
        (pb.net_profit_adj / smt.total_store_profit) * 100 AS profit_share_pct,
        RANK() OVER (PARTITION BY pb.ss_store_sk, pb.d_year, pb.d_month_seq ORDER BY pb.net_profit_adj DESC) AS category_rank,
        LAG(pb.net_profit_adj) OVER (PARTITION BY pb.ss_store_sk ORDER BY pb.d_year, pb.d_month_seq) AS prev_month_profit,
        CASE
            WHEN LAG(pb.net_profit_adj) OVER (PARTITION BY pb.ss_store_sk ORDER BY pb.d_year, pb.d_month_seq) = 0 THEN NULL
            ELSE (pb.net_profit_adj - LAG(pb.net_profit_adj) OVER (PARTITION BY pb.ss_store_sk ORDER BY pb.d_year, pb.d_month_seq)) /
                 LAG(pb.net_profit_adj) OVER (PARTITION BY pb.ss_store_sk ORDER BY pb.d_year, pb.d_month_seq)
        END AS mom_profit_growth
    FROM profit_by_category pb
    JOIN store_month_totals smt
        ON pb.ss_store_sk = smt.ss_store_sk
       AND pb.d_year = smt.d_year
       AND pb.d_month_seq = smt.d_month_seq
    WHERE pb.net_profit_adj > 0
      AND pb.i_category IS NOT NULL
) sub
WHERE sub.category_rank <= 3
ORDER BY sub.store_sk, sub.d_year, sub.d_month_seq, sub.category_rank
