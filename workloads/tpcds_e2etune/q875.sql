WITH catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY cs.cs_bill_customer_sk, d.d_year, d.d_month_seq
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY ss.ss_customer_sk, d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        COALESCE(c.customer_sk, s.customer_sk) AS customer_sk,
        COALESCE(c.d_year, s.d_year) AS year,
        COALESCE(c.d_month_seq, s.d_month_seq) AS month_seq,
        COALESCE(c.net_profit, 0) + COALESCE(s.net_profit, 0) AS total_net_profit,
        COALESCE(c.txn_cnt, 0) + COALESCE(s.txn_cnt, 0) AS total_txn_cnt,
        (COALESCE(c.avg_discount, 0) * COALESCE(c.txn_cnt, 0) + COALESCE(s.avg_discount, 0) * COALESCE(s.txn_cnt, 0))
            / NULLIF(COALESCE(c.txn_cnt, 0) + COALESCE(s.txn_cnt, 0), 0) AS weighted_avg_discount
    FROM catalog_sales_agg c
    FULL OUTER JOIN store_sales_agg s
        ON c.customer_sk = s.customer_sk
        AND c.d_year = s.d_year
        AND c.d_month_seq = s.d_month_seq
)
SELECT
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    comb.year,
    comb.month_seq,
    comb.total_net_profit,
    comb.total_txn_cnt,
    comb.weighted_avg_discount,
    RANK() OVER (PARTITION BY comb.year ORDER BY comb.total_net_profit DESC) AS profit_rank_year
FROM combined comb
JOIN customer cu ON comb.customer_sk = cu.c_customer_sk
WHERE comb.total_net_profit > 5000
ORDER BY comb.total_net_profit DESC
LIMIT 20
