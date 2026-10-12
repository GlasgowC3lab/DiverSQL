WITH s_sales AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        d.d_date AS sale_date,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CASE WHEN ss.ss_quantity = 0 THEN NULL ELSE ss.ss_net_paid / ss.ss_quantity END AS avg_price_per_item,
        concat(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS cust_name,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM store_sales ss
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_net_paid IS NOT NULL
),
w_sales AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        NULL AS store_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        d.d_date AS sale_date,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_quantity = 0 THEN NULL ELSE ws.ws_net_paid / ws.ws_quantity END AS avg_price_per_item,
        concat(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS cust_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_net_paid IS NOT NULL
),
combined_sales AS (
    SELECT * FROM s_sales
    UNION ALL
    SELECT * FROM w_sales
),
top_customers AS (
    SELECT customer_sk
    FROM (
        SELECT customer_sk, SUM(net_paid) AS total_spent
        FROM s_sales
        GROUP BY customer_sk
        ORDER BY total_spent DESC
        LIMIT 10
    ) tc
),
sales_with_lag AS (
    SELECT
        cs.customer_sk,
        cs.sold_date_sk,
        cs.sale_date,
        cs.store_sk,
        cs.quantity,
        cs.net_paid,
        cs.net_profit,
        cs.avg_price_per_item,
        cs.cust_name,
        LAG(cs.avg_price_per_item, 1) OVER (PARTITION BY cs.customer_sk ORDER BY cs.sold_date_sk) AS prev_avg_price,
        CASE
            WHEN LAG(cs.avg_price_per_item, 1) OVER (PARTITION BY cs.customer_sk ORDER BY cs.sold_date_sk) IS NULL THEN 'N/A'
            ELSE CONCAT('Δ', CAST(cs.avg_price_per_item - LAG(cs.avg_price_per_item, 1) OVER (PARTITION BY cs.customer_sk ORDER BY cs.sold_date_sk) AS VARCHAR))
        END AS price_change,
        ROW_NUMBER() OVER (PARTITION BY cs.customer_sk ORDER BY cs.sold_date_sk DESC) AS seq_desc
    FROM combined_sales cs
    WHERE cs.customer_sk IN (SELECT customer_sk FROM top_customers)
),
store_ret AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_returned_date_sk AS returned_date_sk,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        MAX(sr.sr_return_quantity) AS max_quantity,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, sr.sr_returned_date_sk, d.d_year
),
catalog_ret AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_returned_date_sk AS returned_date_sk,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amt,
        MAX(cr.cr_return_quantity) AS max_quantity,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_returning_customer_sk, cr.cr_returned_date_sk, d.d_year
),
union_returns AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
),
final AS (
    SELECT
        swl.customer_sk,
        swl.sold_date_sk,
        swl.sale_date,
        swl.store_sk,
        swl.quantity,
        swl.net_paid,
        swl.net_profit,
        swl.avg_price_per_item,
        swl.prev_avg_price,
        swl.price_change,
        swl.cust_name,
        swl.seq_desc,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        COALESCE(r.max_quantity, 0) AS max_return_quantity,
        COALESCE(r.returns_cnt, 0) AS total_returns,
        CASE WHEN COALESCE(r.total_return_amt, 0) > 1000 THEN TRUE ELSE FALSE END AS high_return_flag,
        RANK() OVER (PARTITION BY swl.customer_sk ORDER BY swl.avg_price_per_item DESC) AS price_rank,
        GREATEST(swl.avg_price_per_item, 0.0) AS non_negative_avg_price,
        CASE WHEN REGEXP_LIKE(swl.cust_name, '^A') THEN 'StartsWithA' ELSE 'Other' END AS name_grp,
        (SELECT COUNT(*) FROM combined_sales cs2 WHERE cs2.customer_sk = swl.customer_sk AND cs2.sold_date_sk < swl.sold_date_sk) AS prior_sales_cnt
    FROM sales_with_lag swl
    LEFT JOIN union_returns r
        ON swl.customer_sk = r.customer_sk
        AND swl.sold_date_sk = r.returned_date_sk
    WHERE swl.price_change IS NOT NULL OR r.total_return_amt IS NOT NULL
)
SELECT
    f.customer_sk,
    c.c_customer_id,
    f.sold_date_sk,
    f.sale_date,
    f.store_sk,
    f.quantity,
    f.net_paid,
    f.net_profit,
    f.avg_price_per_item,
    f.prev_avg_price,
    f.price_change,
    f.cust_name,
    f.total_return_amt,
    f.max_return_quantity,
    f.total_returns,
    f.high_return_flag,
    f.price_rank,
    f.non_negative_avg_price,
    f.name_grp,
    f.prior_sales_cnt,
    CASE WHEN f.high_return_flag AND f.price_rank = 1 THEN 'TOP_RISK' ELSE 'NORMAL' END AS risk_category,
    CASE WHEN f.total_returns = 0 THEN NULL ELSE CAST(f.total_returns AS VARCHAR) || ' ret' END AS return_summary
FROM final f
LEFT JOIN customer c ON f.customer_sk = c.c_customer_sk
ORDER BY f.high_return_flag DESC, f.price_rank ASC, f.sale_date DESC NULLS LAST
LIMIT 100
