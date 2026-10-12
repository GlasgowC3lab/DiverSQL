WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cp.cp_catalog_page_id,
        cp.cp_type,
        i.i_item_id,
        i.i_color,
        w.w_warehouse_id,
        w.w_state,
        w.w_city,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM sampled_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_color IN ('red', 'smoke')
      AND w.w_state IN ('GA', 'IN')
      AND cp.cp_type = 'Digital'
),
agg_page AS (
    SELECT
        cp_catalog_page_id,
        SUM(cs_quantity)               AS total_quantity,
        SUM(cs_net_paid)               AS total_net_paid,
        SUM(cr_return_amount)          AS total_return_amount,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_data
    GROUP BY cp_catalog_page_id
),
overall_stats AS (
    SELECT
        AVG(total_quantity) AS avg_qty,
        AVG(total_net_paid) AS avg_net_paid,
        AVG(total_return_amount) AS avg_return_amount,
        AVG(order_cnt) AS avg_orders
    FROM agg_page
),
order_numbers_sales AS (
    SELECT DISTINCT cs_order_number
    FROM sampled_sales
    WHERE cs_quantity > 5
),
order_numbers_returns AS (
    SELECT DISTINCT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 100
),
order_numbers_intersect AS (
    SELECT cs_order_number FROM order_numbers_sales
    INTERSECT
    SELECT cr_order_number FROM order_numbers_returns
),
order_numbers_exclude AS (
    SELECT cs_order_number FROM order_numbers_sales
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
),
union_orders AS (
    SELECT cs_order_number FROM order_numbers_sales
    UNION
    SELECT cr_order_number FROM catalog_returns
),
scalar_avg_qty AS (
    SELECT AVG(cs_quantity) AS avg_qty FROM sampled_sales
),
expanded_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        w.w_city,
        state_city
    FROM warehouse w
    CROSS JOIN UNNEST(ARRAY[w.w_state, w.w_city]) AS t(state_city)
)
SELECT
    a.cp_catalog_page_id,
    a.total_quantity,
    a.total_net_paid,
    o.avg_qty            AS overall_avg_quantity,
    i_cnt.intersect_cnt  AS intersect_order_count,
    e_cnt.excluded_cnt   AS excluded_order_count,
    u_cnt.union_cnt      AS union_order_count,
    s.avg_qty            AS sampled_avg_quantity,
    ew.state_city        AS warehouse_state_or_city
FROM agg_page a
CROSS JOIN overall_stats o
CROSS JOIN (SELECT COUNT(*) AS intersect_cnt FROM order_numbers_intersect) i_cnt
CROSS JOIN (SELECT COUNT(*) AS excluded_cnt FROM order_numbers_exclude) e_cnt
CROSS JOIN (SELECT COUNT(*) AS union_cnt FROM union_orders) u_cnt
CROSS JOIN scalar_avg_qty s
CROSS JOIN expanded_warehouse ew
WHERE a.total_quantity > 100
  AND a.total_net_paid > 1000
  AND a.cp_catalog_page_id IS NOT NULL
ORDER BY a.total_net_paid DESC
LIMIT 100
