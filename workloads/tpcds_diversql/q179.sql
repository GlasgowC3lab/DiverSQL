SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    w.w_gmt_offset
FROM tpcds.warehouse AS w
WHERE w.w_county = 'Bronx County'
  AND w.w_street_type = 'Ave'
