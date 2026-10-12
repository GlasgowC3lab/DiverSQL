WITH
sales_base AS (
    SELECT
        s.s_store_sk,
        d.d_date,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_sk, d.d_date
),
sales_agg AS (
    SELECT
        sb.*,
        ROW_NUMBER() OVER (PARTITION BY sb.s_store_sk ORDER BY sb.total_profit DESC) AS profit_rank
    FROM sales_base sb
),
returns_agg AS (
    SELECT
        r.sr_store_sk,
        d.d_date,
        SUM(r.sr_net_loss) AS total_loss,
        SUM(r.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT r.sr_item_sk) AS distinct_items_returned
    FROM store_returns r
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY r.sr_store_sk, d.d_date
),
store_perf AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COALESCE(sa.total_net_paid, 0) AS total_net_paid,
        COALESCE(sa.total_profit, 0) AS total_profit,
        COALESCE(ra.total_loss, 0) AS total_loss,
        COALESCE(sa.total_quantity, 0) - COALESCE(ra.total_return_qty, 0) AS net_quantity,
        CASE
            WHEN COALESCE(sa.total_profit, 0) = 0 THEN NULL
            ELSE COALESCE(sa.total_profit, 0) / NULLIF(COALESCE(sa.total_net_paid, 0), 0)
        END AS profit_margin,
        sa.profit_rank,
        CASE
            WHEN COALESCE(ra.total_loss, 0) > 0 THEN 'Lossy'
            ELSE 'Profitable'
        END AS performance_flag,
        CONCAT(COALESCE(s.s_store_name, 'UNKNOWN'), '_', COALESCE(s.s_city, '')) AS store_key
    FROM store s
    LEFT JOIN sales_agg sa ON s.s_store_sk = sa.s_store_sk
    LEFT JOIN returns_agg ra ON s.s_store_sk = ra.sr_store_sk AND ra.d_date = sa.d_date
    WHERE s.s_store_name IS NOT NULL
),
store_full AS (
    SELECT
        sp.*,
        ROW_NUMBER() OVER (ORDER BY sp.profit_margin DESC NULLS LAST) AS overall_rank
    FROM store_perf sp
),
top_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rn
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
),
high_return_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(r.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM customer c
    JOIN store_returns r ON c.c_customer_sk = r.sr_customer_sk
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING SUM(r.sr_return_amt_inc_tax) > 500
),
customer_union AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        tc.total_spent AS metric,
        'top_spender' AS category,
        tc.rn AS rank
    FROM top_customers tc
    JOIN customer c ON c.c_customer_id = tc.c_customer_id
    UNION ALL
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hrc.total_return_amount AS metric,
        'high_returner' AS category,
        hrc.return_cnt AS rank
    FROM high_return_customers hrc
    JOIN customer c ON c.c_customer_id = hrc.c_customer_id
)
SELECT
    sf.store_key,
    sf.s_store_name,
    sf.s_city,
    sf.s_state,
    sf.total_net_paid,
    sf.total_profit,
    sf.total_loss,
    sf.net_quantity,
    ROUND(sf.profit_margin, 4) AS profit_margin,
    sf.profit_rank,
    sf.performance_flag,
    sf.overall_rank,
    LOWER(sf.s_store_name) AS lower_store_name,
    (SELECT MAX(r2.sr_return_quantity) FROM store_returns r2 WHERE r2.sr_store_sk = sf.s_store_sk) AS max_return_qty,
    cu.customer_id,
    cu.first_name,
    cu.last_name,
    cu.metric,
    cu.category,
    CASE WHEN cu.category = 'top_spender' THEN 'VIP' ELSE 'AtRisk' END AS customer_segment,
    COALESCE(NULLIF(cu.first_name, ''), 'Anonymous') AS normalized_first_name,
    LENGTH(cu.last_name) AS last_name_len,
    ROW_NUMBER() OVER (PARTITION BY sf.store_key ORDER BY cu.metric DESC) AS rn_store
FROM store_full sf
CROSS JOIN LATERAL (
    SELECT *
    FROM customer_union cu
    WHERE cu.category = 'top_spender'
    ORDER BY cu.metric DESC
    LIMIT 5
) AS cu
WHERE (sf.profit_margin IS NOT NULL AND sf.profit_margin > 0) OR cu.customer_id IS NOT NULL
ORDER BY sf.profit_margin DESC NULLS LAST, sf.s_store_name
LIMIT 100
