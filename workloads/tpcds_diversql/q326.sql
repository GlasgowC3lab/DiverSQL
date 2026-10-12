WITH joined_data AS (
   SELECT
        cr.cr_returned_date_sk,
        ca.ca_state,
        w.w_warehouse_name,
        sm.sm_type,
        td.t_hour,
        td.t_minute,
        td.t_second,
        cr.cr_return_amount,
        cr.cr_return_tax,
        inv.inv_quantity_on_hand,
        ss.ss_net_paid,
        ws.ws_net_paid,
        ws.ws_ext_tax,
        ws.ws_ext_ship_cost,
        p.p_promo_name,
        we.web_site_id
   FROM catalog_returns cr
   INNER JOIN customer_address ca
       ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   INNER JOIN warehouse w
       ON cr.cr_warehouse_sk = w.w_warehouse_sk
   FULL OUTER JOIN inventory inv
       ON w.w_warehouse_sk = inv.inv_warehouse_sk
   INNER JOIN ship_mode sm
       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN time_dim td
       ON cr.cr_returned_time_sk = td.t_time_sk
   LEFT JOIN (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
       ON ss.ss_sold_time_sk = td.t_time_sk
   LEFT JOIN promotion p
       ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN web_sales ws
       ON ws.ws_sold_time_sk = td.t_time_sk
   LEFT JOIN web_site we
       ON ws.ws_web_site_sk = we.web_site_sk
   WHERE td.t_hour BETWEEN 8 AND 20
     AND ca.ca_state = 'TX'
     AND inv.inv_quantity_on_hand > 0
     AND NOT EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = ss.ss_promo_sk)
),
agg_by_state_warehouse AS (
   SELECT
        ca_state,
        w_warehouse_name,
        COUNT(DISTINCT ca_state) AS cnt_state_dist,
        COUNT(DISTINCT w_warehouse_name) AS cnt_warehouse_dist,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(ss_net_paid) AS sum_store_net_paid,
        SUM(ws_net_paid) AS sum_web_net_paid
   FROM joined_data
   GROUP BY ca_state, w_warehouse_name
)
SELECT
    ca_state,
    w_warehouse_name,
    sum_return_amount,
    sum_store_net_paid,
    sum_web_net_paid,
    cnt_state_dist,
    cnt_warehouse_dist,
    AVG(sum_return_amount) OVER () AS avg_return_amount_all,
    ROW_NUMBER() OVER (ORDER BY sum_return_amount DESC) AS row_num
FROM agg_by_state_warehouse
ORDER BY row_num
LIMIT 100
