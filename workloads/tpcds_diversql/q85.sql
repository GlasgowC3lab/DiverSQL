WITH joined AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_type,
        i.i_item_id,
        i.i_current_price,
        hd.hd_vehicle_count,
        sm.sm_code,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_current_price > 50.00
      AND hd.hd_vehicle_count >= 2
      AND s.s_state = 'CA'
      AND cp.cp_type = 'PROMO'
      AND sm.sm_code = 'AIR'
      AND cr.cr_return_amount > 10.00
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        cp_catalog_page_id,
        i_item_id,
        cp_catalog_number,
        SUM(cr_return_amount + sr_return_amt) AS total_return_amount,
        SUM(cr_net_loss + sr_net_loss) AS total_net_loss
    FROM joined
    GROUP BY
        s_store_id,
        s_store_name,
        cp_catalog_page_id,
        i_item_id,
        cp_catalog_number
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.cp_catalog_page_id,
    a.i_item_id,
    a.total_return_amount,
    a.total_net_loss,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg a
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_catalog_number = a.cp_catalog_number
      AND cp2.cp_department = 'HOME'
)
ORDER BY loss_rank
LIMIT 100
