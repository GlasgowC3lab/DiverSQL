WITH joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        d.d_date,
        d.d_year,
        s.s_store_id,
        s.s_state,
        s.s_store_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        hd.hd_vehicle_count,
        i.inv_quantity_on_hand
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory i
      ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND hd.hd_vehicle_count >= 1
),
sub1 AS (
    SELECT
        s_store_id,
        d_date,
        SUM(sr_return_amt) AS total_return,
        COUNT(*) AS ret_cnt
    FROM joined_data
    GROUP BY s_store_id, d_date
    HAVING SUM(sr_return_amt) > 1000
),
sub2 AS (
    SELECT
        s_store_id,
        d_date,
        SUM(sr_return_amt) AS total_return,
        COUNT(*) AS ret_cnt
    FROM joined_data
    GROUP BY s_store_id, d_date
    HAVING SUM(sr_return_amt) < 5000
),
intersect_set AS (
    SELECT s_store_id, d_date FROM sub1
    INTERSECT
    SELECT s_store_id, d_date FROM sub2
),
union_set AS (
    SELECT s_store_id, d_date FROM sub1
    UNION
    SELECT s_store_id, d_date FROM sub2
),
final_agg AS (
    SELECT
        jd.s_store_id,
        jd.d_date,
        SUM(jd.sr_return_amt) AS total_return,
        COUNT(*) AS ret_cnt,
        CASE WHEN SUM(jd.sr_return_amt) > 3000 THEN 'High' ELSE 'Medium' END AS return_category,
        RANK() OVER (PARTITION BY jd.s_store_id ORDER BY SUM(jd.sr_return_amt) DESC) AS rnk
    FROM joined_data jd
    JOIN intersect_set iset
      ON jd.s_store_id = iset.s_store_id
     AND jd.d_date = iset.d_date
    JOIN union_set uset
      ON jd.s_store_id = uset.s_store_id
     AND jd.d_date = uset.d_date
    GROUP BY jd.s_store_id, jd.d_date
)
SELECT
    f.s_store_id,
    f.d_date,
    f.total_return,
    f.ret_cnt,
    f.return_category,
    f.rnk
FROM final_agg f
ORDER BY f.return_category DESC, f.rnk
OFFSET 0 LIMIT 100
