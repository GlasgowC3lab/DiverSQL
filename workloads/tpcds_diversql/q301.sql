WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_item_id,
        i.i_brand,
        i.i_current_price,
        p.p_promo_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        w.w_state,
        wp.wp_type,
        ws.web_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND w.w_state = 'TX'
)
SELECT
    d_year,
    i_brand,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    SUM(CASE WHEN cd_gender = 'M' THEN inv_quantity_on_hand ELSE 0 END) AS male_quantity,
    AVG(ib_lower_bound) AS avg_income_lower,
    MAX(w_state) AS any_state
FROM (
    SELECT d_year, i_brand, i_item_id, cd_gender, inv_quantity_on_hand, ib_lower_bound, w_state
    FROM joined
    UNION DISTINCT
    SELECT d_year, i_brand, i_item_id, cd_gender, inv_quantity_on_hand, ib_lower_bound, w_state
    FROM joined
    WHERE i_current_price > 100
) u
GROUP BY d_year, i_brand
ORDER BY distinct_items DESC
LIMIT 10
