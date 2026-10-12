WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state AS store_state,
        w.w_warehouse_id,
        w.w_city AS warehouse_city,
        c.c_customer_id,
        c.c_birth_country,
        ca.ca_state,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND c.c_birth_country = 'United States'
      AND ca.ca_state = 'TX'
      AND hd.hd_income_band_sk = 16
      AND w.w_city = 'Seattle'
),
agg_data AS (
    SELECT
        j.s_store_id,
        j.w_warehouse_id,
        j.d_month_seq,
        COUNT(*) AS return_cnt,
        SUM(j.cr_return_amount) AS total_return_amount,
        AVG(j.cr_return_tax) AS avg_return_tax,
        MAX(j.cr_return_quantity) AS max_return_qty,
        ROW_NUMBER() OVER (PARTITION BY j.s_store_id ORDER BY SUM(j.cr_return_amount) DESC) AS store_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(j.cr_return_amount) DESC) AS global_rank,
        (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2001) AS max_date_2001
    FROM joined_data j
    GROUP BY j.s_store_id, j.w_warehouse_id, j.d_month_seq
    HAVING SUM(j.cr_return_amount) > 0
)
SELECT
    a.s_store_id,
    a.w_warehouse_id,
    a.d_month_seq,
    a.return_cnt,
    a.total_return_amount,
    a.avg_return_tax,
    a.max_return_qty,
    a.store_rank,
    a.global_rank,
    a.max_date_2001
FROM agg_data a
WHERE a.store_rank <= 3
ORDER BY a.total_return_amount DESC
LIMIT 100
