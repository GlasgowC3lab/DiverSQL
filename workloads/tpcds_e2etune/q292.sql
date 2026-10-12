WITH cp AS (
    SELECT cp_department,
           cp_start_date_sk,
           COUNT(*) AS page_cnt
    FROM catalog_page
    WHERE cp_department IS NOT NULL
    GROUP BY cp_department, cp_start_date_sk
),
promo AS (
    SELECT p_start_date_sk,
           SUM(p_cost) AS total_promo_cost,
           COUNT(DISTINCT p_promo_id) AS promo_cnt
    FROM promotion
    WHERE p_discount_active = 'Y'
    GROUP BY p_start_date_sk
),
time_agg AS (
    SELECT t_time_sk,
           t_shift,
           AVG(t_hour) AS avg_hour
    FROM time_dim
    GROUP BY t_time_sk, t_shift
),
warehouse_agg AS (
    SELECT COUNT(DISTINCT w_warehouse_id) AS ca_warehouse_cnt
    FROM warehouse
    WHERE w_state = 'CA'
)
SELECT
    department,
    shift,
    total_pages,
    total_promo_cost,
    total_promos,
    avg_start_hour,
    ca_warehouse_cnt,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS cost_rank
FROM (
    SELECT
        cp.cp_department AS department,
        time_agg.t_shift AS shift,
        SUM(cp.page_cnt) AS total_pages,
        SUM(promo.total_promo_cost) AS total_promo_cost,
        SUM(promo.promo_cnt) AS total_promos,
        AVG(time_agg.avg_hour) AS avg_start_hour,
        warehouse_agg.ca_warehouse_cnt
    FROM cp
    JOIN promo ON cp.cp_start_date_sk = promo.p_start_date_sk
    JOIN time_agg ON cp.cp_start_date_sk = time_agg.t_time_sk
    CROSS JOIN warehouse_agg
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY cp.cp_department, time_agg.t_shift, warehouse_agg.ca_warehouse_cnt
    HAVING SUM(promo.total_promo_cost) > 10000
) t
ORDER BY total_promo_cost DESC
LIMIT 50
