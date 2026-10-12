WITH
    store_returns_filtered AS (
        SELECT
            sr.sr_store_sk AS sr_store_sk,
            sr.sr_return_amt,
            s.s_store_name,
            s.s_geography_class,
            i.i_category_id,
            t.t_hour
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE i.i_category_id = 2
          AND t.t_hour BETWEEN 9 AND 17
    ),
    stores_with_promotions AS (
        SELECT DISTINCT sr.sr_store_sk AS sr_store_sk
        FROM store_returns sr
        JOIN promotion p ON sr.sr_item_sk = p.p_item_sk
        WHERE p.p_discount_active = 'Y'
    ),
    stores_defective_returns AS (
        SELECT DISTINCT sr.sr_store_sk AS sr_store_sk
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc = 'Defective'
    ),
    intersected_stores AS (
        SELECT sr_store_sk
        FROM store_returns_filtered
        GROUP BY sr_store_sk
        INTERSECT
        SELECT sr_store_sk
        FROM stores_with_promotions
    ),
    final_set AS (
        SELECT sr_store_sk
        FROM intersected_stores
        EXCEPT
        SELECT sr_store_sk
        FROM stores_defective_returns
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_geography_class,
    SUM(r.sr_return_amt) AS total_return_amount,
    CASE WHEN SUM(r.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(r.sr_return_amt) DESC) AS state_return_rank
FROM final_set f
JOIN store s ON f.sr_store_sk = s.s_store_sk
JOIN store_returns r ON s.s_store_sk = r.sr_store_sk
WHERE EXISTS (
    SELECT 1
    FROM customer_demographics cd
    WHERE r.sr_cdemo_sk = cd.cd_demo_sk
      AND cd.cd_credit_rating = 'Excellent'
)
GROUP BY s.s_store_id, s.s_store_name, s.s_geography_class, s.s_state
ORDER BY total_return_amount DESC
LIMIT 100
