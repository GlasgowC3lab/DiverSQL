WITH item_inventory AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY i.i_category, i.i_brand, i.i_item_id
),
high_income_households AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(*) AS hh_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ii.i_category,
    ii.i_brand,
    SUM(ii.total_qty) AS category_total_qty,
    AVG(ii.avg_price) AS category_avg_price,
    MAX(ii.total_qty) AS max_item_qty,
    (SELECT COALESCE(SUM(hh.hh_count), 0) FROM high_income_households hh) AS total_high_income_hh,
    (SELECT COUNT(*) FROM reason r WHERE r.r_reason_desc LIKE '%promotion%') AS promotion_reason_count,
    (SELECT COUNT(DISTINCT t_shift) FROM time_dim td WHERE td.t_hour BETWEEN 0 AND 23) AS distinct_shifts
FROM item_inventory ii
GROUP BY ii.i_category, ii.i_brand
HAVING SUM(ii.total_qty) > 1000
ORDER BY category_total_qty DESC
LIMIT 20
