WITH joined AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_gmt_offset,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        p.p_cost,
        sr.sr_return_amt,
        wr.wr_return_amt,
        d.d_current_year
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_web_page_sk = wr.wr_web_page_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS row_num,
    call_center_id,
    call_center_name,
    catalog_page_id,
    catalog_number,
    warehouse_name,
    total_quantity,
    total_promo_cost,
    total_return_amt,
    avg_return_amt
FROM (
    SELECT
        cc_call_center_id AS call_center_id,
        cc_name AS call_center_name,
        cp_catalog_page_id AS catalog_page_id,
        cp_catalog_number AS catalog_number,
        w_warehouse_name AS warehouse_name,
        SUM(inv_quantity_on_hand) AS total_quantity,
        SUM(p_cost) AS total_promo_cost,
        SUM(sr_return_amt + wr_return_amt) AS total_return_amt,
        AVG(sr_return_amt + wr_return_amt) AS avg_return_amt
    FROM joined
    WHERE d_current_year = 'Y'
      AND cc_gmt_offset >= -5
      AND cp_catalog_number BETWEEN 5 AND 20
      AND w_warehouse_sq_ft > 500000
    GROUP BY cc_call_center_id, cc_name, cp_catalog_page_id, cp_catalog_number, w_warehouse_name
) agg
ORDER BY total_return_amt DESC
LIMIT 100
