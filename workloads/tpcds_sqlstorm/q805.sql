WITH date_filtered AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year IN (1998, 1999)
),
store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS trans_cnt,
        MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
    FROM store_sales ss
    JOIN date_filtered df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss.ss_store_sk, ss.ss_customer_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_call_center_sk AS store_key,
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS trans_cnt,
        MAX(cs.cs_sold_date_sk) AS last_sale_date_sk
    FROM catalog_sales cs
    JOIN date_filtered df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs.cs_call_center_sk, cs.cs_bill_customer_sk
),
combined_sales AS (
    SELECT
        ssa.ss_store_sk AS store_sk,
        ssa.ss_customer_sk AS customer_sk,
        ssa.total_net_paid,
        ssa.total_net_profit,
        ssa.trans_cnt,
        ssa.last_sale_date_sk,
        'store' AS sales_channel
    FROM store_sales_agg ssa
    UNION ALL
    SELECT
        csa.store_key AS store_sk,
        csa.customer_sk,
        csa.total_net_paid,
        csa.total_net_profit,
        csa.trans_cnt,
        csa.last_sale_date_sk,
        'catalog' AS sales_channel
    FROM catalog_sales_agg csa
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country
    FROM store s
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
return_metrics AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_filtered df ON sr.sr_returned_date_sk = df.d_date_sk
    GROUP BY sr.sr_store_sk, sr.sr_customer_sk
),
final AS (
    SELECT
        si.s_store_sk AS store_sk,
        si.s_store_name AS store_name,
        si.s_city AS city,
        si.s_state AS state,
        ci.full_name,
        cs.sales_channel,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.trans_cnt,
        COALESCE(rm.total_return_amt, 0) AS total_return_amt,
        COALESCE(rm.return_cnt, 0) AS return_cnt,
        cs.total_net_profit - COALESCE(rm.total_return_amt, 0) AS net_profit_after_returns,
        CASE
            WHEN cs.trans_cnt > 0 THEN cs.total_net_paid / cs.trans_cnt
            ELSE NULL
        END AS avg_paid_per_trans,
        ROW_NUMBER() OVER (
            PARTITION BY si.s_store_sk
            ORDER BY (cs.total_net_profit - COALESCE(rm.total_return_amt, 0)) DESC
        ) AS profit_rank,
        CASE
            WHEN ci.cd_gender IS NULL THEN 'UNKNOWN'
            ELSE ci.cd_gender
        END AS gender,
        COALESCE(ci.cd_marital_status, 'UNKNOWN') AS marital_status,
        COALESCE(ci.hd_income_band_sk, -1) AS income_band_sk,
        (
            SELECT COUNT(*)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = cs.customer_sk
              AND ss2.ss_store_sk = si.s_store_sk
              AND ss2.ss_sold_date_sk = cs.last_sale_date_sk
        ) AS same_day_sales_cnt,
        (
            SELECT MAX(ss3.ss_net_paid_inc_tax)
            FROM store_sales ss3
            WHERE ss3.ss_customer_sk = cs.customer_sk
              AND ss3.ss_store_sk = si.s_store_sk
        ) AS max_single_sale
    FROM combined_sales cs
    JOIN store_info si ON cs.store_sk = si.s_store_sk
    LEFT JOIN customer_info ci ON cs.customer_sk = ci.c_customer_sk
    LEFT JOIN return_metrics rm ON cs.store_sk = rm.sr_store_sk AND cs.customer_sk = rm.sr_customer_sk
    WHERE cs.total_net_profit > (
        SELECT COALESCE(AVG(cs_sub.total_net_profit), 0)
        FROM combined_sales cs_sub
        WHERE cs_sub.store_sk = cs.store_sk
    )
)
SELECT
    store_sk,
    store_name,
    city,
    state,
    full_name,
    sales_channel,
    profit_rank,
    total_net_profit,
    total_return_amt,
    net_profit_after_returns,
    avg_paid_per_trans,
    gender,
    marital_status,
    income_band_sk,
    same_day_sales_cnt,
    max_single_sale
FROM final
WHERE profit_rank <= 5
ORDER BY store_sk, profit_rank
