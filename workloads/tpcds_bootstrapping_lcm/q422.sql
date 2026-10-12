SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    p.p_promo_name,
    p.p_cost,
    s.s_store_id,
    s.s_city,
    d_cp_end.d_date AS store_closed_date,
    ws.web_site_id,
    ws.web_name,
    d_cp_start.d_date AS website_open_date,
    d_ws_close.d_date AS website_close_date,
    GREATEST(
        0,
        date_diff('day', d_cp_start.d_date, LEAST(d_cp_end.d_date, d_p_end.d_date))
    ) AS overlapping_days
FROM catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cp_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_p_end.d_date >= d_cp_start.d_date
  AND d_p_end.d_date <= d_cp_end.d_date
ORDER BY overlapping_days DESC, p.p_cost DESC
