WITH returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason,
        COUNT(sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
),
inventory_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        SUM(w.w_warehouse_sq_ft) AS total_warehouse_sq_ft
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq
),
promotion_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        COUNT(DISTINCT p.p_promo_id) AS num_promotions,
        AVG(p.p_cost) AS avg_promotion_cost
    FROM promotion p
    JOIN date_dim d
      ON p.p_start_date_sk <= d.d_date_sk
     AND p.p_end_date_sk >= d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    r.year,
    r.month_seq,
    r.reason,
    r.num_returns,
    r.total_return_amount,
    r.avg_return_quantity,
    r.total_net_loss,
    COALESCE(i.total_inventory_on_hand, 0) AS total_inventory_on_hand,
    COALESCE(i.total_warehouse_sq_ft, 0) AS total_warehouse_sq_ft,
    COALESCE(p.num_promotions, 0) AS num_promotions,
    COALESCE(p.avg_promotion_cost, 0) AS avg_promotion_cost
FROM returns_monthly r
LEFT JOIN inventory_monthly i
  ON r.year = i.year AND r.month_seq = i.month_seq
LEFT JOIN promotion_monthly p
  ON r.year = p.year AND r.month_seq = p.month_seq
ORDER BY r.year ASC, r.month_seq ASC, r.total_return_amount DESC
LIMIT 100
