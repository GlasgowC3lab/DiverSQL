/* goal: Summarize net revenue and transaction counts per store, year and promotion, enriched with customer and demographic info, while ensuring at least one catalog sale exists for the customer on the same date. Categorize revenue levels using CASE. */
WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
),
base AS (
    SELECT
        s.s_store_name            AS s_store_name,
        d.d_year                  AS d_year,
        p.p_promo_name            AS p_promo_name,
        ss_agg.total_net_paid,
        ss_agg.sales_cnt,
        hd_bill.hd_vehicle_count AS hd_vehicle_count,
        c.c_customer_sk           AS c_customer_sk
    FROM ss_agg
    JOIN store s
        ON ss_agg.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss_agg.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss_agg.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_sold_date_sk = d.d_date_sk
    )
)
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    CASE WHEN SUM(total_net_paid) > 50000 THEN 'High' ELSE 'Medium' END AS revenue_category,
    SUM(total_net_paid)                 AS net_paid_sum,
    SUM(sales_cnt)                      AS total_transactions,
    AVG(hd_vehicle_count)              AS avg_vehicle_count,
    COUNT(DISTINCT c_customer_sk)       AS distinct_customers
FROM base
GROUP BY
    s_store_name,
    d_year,
    p_promo_name
ORDER BY d_year DESC, net_paid_sum DESC
LIMIT 100
