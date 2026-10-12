WITH filtered_cc AS (
    SELECT *
    FROM call_center
    WHERE cc_gmt_offset BETWEEN -8.00 AND -5.00
      AND cc_rec_end_date >= DATE '2000-01-01'
),
filtered_item AS (
    SELECT *
    FROM item
    WHERE i_current_price > 10.00
      AND i_rec_start_date <= DATE '2001-12-31'
),
joined AS (
    SELECT
        cc.cc_state AS state,
        i.i_category AS category,
        cc.cc_call_center_id AS call_center_id,
        i.i_wholesale_cost AS wholesale_cost,
        i.i_current_price AS current_price
    FROM filtered_cc cc
    JOIN filtered_item i
      ON cc.cc_mkt_id = i.i_brand_id
    WHERE cc.cc_country = 'United States'
      AND i.i_color IN ('Red', 'Blue')
),
agg AS (
    SELECT
        state,
        category,
        COUNT(DISTINCT call_center_id) AS num_call_centers,
        SUM(wholesale_cost) AS total_wholesale_cost,
        AVG(current_price) AS avg_current_price
    FROM joined
    GROUP BY state, category
    HAVING COUNT(DISTINCT call_center_id) >= 2
)
SELECT
    state,
    category,
    num_call_centers,
    total_wholesale_cost,
    avg_current_price,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_wholesale_cost DESC) AS rank_by_wholesale
FROM agg
ORDER BY state, total_wholesale_cost DESC
LIMIT 100
