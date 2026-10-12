WITH promo_periods AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        ds.d_date AS start_date,
        de.d_date AS end_date,
        p.p_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN date_dim de ON p.p_end_date_sk = de.d_date_sk
    WHERE p.p_cost > 1000
),
promo_returns AS (
    SELECT
        pp.p_promo_id,
        pp.p_promo_name,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promo_periods pp
        ON dr.d_date BETWEEN pp.start_date AND pp.end_date
    WHERE sm.sm_type IN ('Standard', 'Express')
    GROUP BY pp.p_promo_id, pp.p_promo_name, sm.sm_type
    HAVING SUM(cr.cr_return_amount) > 500
),
promo_totals AS (
    SELECT
        p_promo_id,
        p_promo_name,
        SUM(total_return_amount) AS promo_total_return_amount,
        SUM(total_return_inc_tax) AS promo_total_return_inc_tax,
        SUM(total_net_loss) AS promo_total_net_loss
    FROM promo_returns
    GROUP BY p_promo_id, p_promo_name
)
SELECT
    pr.p_promo_id,
    pr.p_promo_name,
    pr.sm_type,
    pr.total_return_amount,
    pr.total_return_inc_tax,
    pr.avg_return_quantity,
    pr.total_net_loss,
    pr.distinct_items_returned,
    RANK() OVER (ORDER BY pt.promo_total_return_amount DESC) AS promo_rank,
    RANK() OVER (PARTITION BY pr.p_promo_id ORDER BY pr.total_return_amount DESC) AS ship_mode_rank
FROM promo_returns pr
JOIN promo_totals pt ON pr.p_promo_id = pt.p_promo_id
ORDER BY pt.promo_total_return_amount DESC, pr.total_return_amount DESC
LIMIT 100
