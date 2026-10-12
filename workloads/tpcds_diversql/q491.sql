WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)   -- 10% random sample of store_sales
    ),
    agg_sales AS (
        SELECT
            ss_store_sk,
            ss_hdemo_sk,
            ss_promo_sk,
            SUM(ss_net_paid)       AS total_net_paid,
            SUM(ss_quantity)       AS total_quantity,
            COUNT(*)               AS sales_cnt
        FROM sampled_sales
        WHERE ss_net_paid > 100                -- predicate 1
          AND ss_quantity BETWEEN 1 AND 10     -- predicate 2
        GROUP BY ss_store_sk, ss_hdemo_sk, ss_promo_sk
    ),
    filtered_hd AS (
        SELECT *
        FROM household_demographics
        WHERE hd_vehicle_count >= 0                -- predicate 3
          AND hd_dep_count <= 5                    -- predicate 4
          AND hd_demo_sk IN (
                SELECT ss_hdemo_sk
                FROM store_sales
                WHERE ss_list_price > 50          -- predicate inside IN subquery
          )
    ),
    joined_data AS (
        SELECT
            a.ss_store_sk,
            a.ss_hdemo_sk,
            a.ss_promo_sk,
            a.total_net_paid,
            a.total_quantity,
            hd.hd_income_band_sk,
            hd.hd_vehicle_count,
            hd.hd_dep_count,
            ib.ib_upper_bound,
            p.p_promo_name,
            p.p_channel_email,
            s.s_store_name,
            s.s_state,
            s.s_number_employees,
            s.s_gmt_offset
        FROM agg_sales a
        JOIN filtered_hd hd
          ON a.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
          ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN promotion p
          ON a.ss_promo_sk = p.p_promo_sk
        JOIN store s
          ON a.ss_store_sk = s.s_store_sk
        WHERE ib.ib_upper_bound <= 150000          -- predicate 5
          AND p.p_discount_active = 'Y'           -- predicate 6
    ),
    returns_with_reason AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_reason_sk,
            wr.wr_return_amt,
            r.r_reason_desc,
            hd.hd_vehicle_count,
            hd.hd_dep_count
        FROM web_returns wr
        FULL OUTER JOIN reason r
          ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN household_demographics hd
          ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE wr.wr_return_amt > 0
    ),
    lateral_calc AS (
        SELECT
            jd.*, 
            RANK() OVER (PARTITION BY jd.s_state ORDER BY jd.total_net_paid DESC) AS state_sales_rank,
            (SELECT AVG(total_quantity) FROM agg_sales) AS avg_quantity_overall,
            lc.vehicle_ratio
        FROM joined_data jd
        LEFT JOIN LATERAL (
            SELECT
                CAST(jd.hd_vehicle_count AS double) / NULLIF(jd.s_number_employees, 0) AS vehicle_ratio
        ) lc ON TRUE
    ),
    union_all AS (
        SELECT
            state_sales_rank,
            s_state,
            total_net_paid,
            total_quantity,
            p_promo_name,
            hd_vehicle_count,
            ib_upper_bound
        FROM lateral_calc
        UNION DISTINCT
        SELECT
            NULL AS state_sales_rank,
            s_state,
            total_net_paid,
            total_quantity,
            p_promo_name,
            hd_vehicle_count,
            ib_upper_bound
        FROM lateral_calc
        WHERE total_net_paid < 500
    )
SELECT
    state_sales_rank,
    s_state,
    total_net_paid,
    total_quantity,
    p_promo_name,
    hd_vehicle_count,
    ib_upper_bound
FROM union_all
ORDER BY state_sales_rank NULLS LAST, total_net_paid DESC
LIMIT 100
